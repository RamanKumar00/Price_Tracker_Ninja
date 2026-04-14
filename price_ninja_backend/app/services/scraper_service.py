"""Web scraping service for Amazon.in and Flipkart.

Uses Selenium with headless Chrome and BeautifulSoup for parsing.
Includes rate limiting, retry logic, and user-agent rotation.
"""

import time
import random
import re
from datetime import datetime
from typing import Dict, Optional

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, WebDriverException
from bs4 import BeautifulSoup

from app.models import Platform
from app.utils.logger import get_logger
from app.utils.exceptions import ScraperException
from app.utils.validators import extract_price_from_text, detect_platform
from config import settings

logger = get_logger("scraper")

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0",
]


class ScraperService:
    """Scrapes product prices from Amazon.in and Flipkart."""

    def __init__(self):
        self._last_scrape_time: float = 0

    def _rate_limit(self):
        """Enforce minimum delay between scrape requests."""
        elapsed = time.time() - self._last_scrape_time
        wait = settings.SCRAPE_RATE_LIMIT_SECONDS - elapsed
        if wait > 0:
            logger.info(f"Rate limiting: waiting {wait:.1f}s")
            time.sleep(wait)
        self._last_scrape_time = time.time()

    def _get_chrome_driver(self) -> webdriver.Chrome:
        """Initialize headless Chrome WebDriver."""
        options = Options()
        options.add_argument("--headless=new")
        options.add_argument("--start-maximized")
        options.add_argument("--disable-extensions")
        options.add_argument("--disable-gpu")
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-blink-features=AutomationControlled")
        options.add_argument("--disable-software-rasterizer")
        options.add_argument(f"user-agent={random.choice(USER_AGENTS)}")
        options.add_experimental_option("excludeSwitches", ["enable-automation"])
        options.add_experimental_option("useAutomationExtension", False)

        try:
            # Explicitly set paths for the joyzoursky/python-chromedriver image
            options.binary_location = "/usr/bin/google-chrome"
            
            # Using the pre-installed ChromeDriver in the Docker image
            chrome_service = Service(executable_path="/usr/bin/chromedriver")
            
            driver = webdriver.Chrome(service=chrome_service, options=options)
            driver.execute_cdp_cmd(
                "Page.addScriptToEvaluateOnNewDocument",
                {
                    "source": """
                    Object.defineProperty(navigator, 'webdriver', {get: () => undefined})
                    """
                },
            )
            driver.set_page_load_timeout(settings.SCRAPE_TIMEOUT_SECONDS + 10)
            return driver
        except Exception as e:
            logger.error(f"Chrome driver init failed: {e}")
            raise ScraperException(f"Could not start Chrome: {e}")

    def scrape(self, url: str) -> Dict:
        """Scrape a product URL. Auto-detects platform."""
        platform = detect_platform(url)
        if platform == Platform.AMAZON:
            return self.scrape_amazon(url)
        elif platform == Platform.FLIPKART:
            return self.scrape_flipkart(url)
        elif platform == Platform.MYNTRA:
            return self.scrape_myntra(url)
        elif platform == Platform.EBAY:
            return self.scrape_ebay(url)
        else:
            raise ScraperException(f"Unsupported platform for URL: {url}")

    def scrape_amazon(self, url: str, retries: int = 3) -> Dict:
        """Scrape Amazon.in product details with retry logic."""
        self._rate_limit()

        for attempt in range(1, retries + 1):
            driver = None
            try:
                logger.info(f"Scraping Amazon (attempt {attempt}): {url[:80]}...")
                driver = self._get_chrome_driver()
                driver.get(url)

                # Wait for price element
                WebDriverWait(driver, settings.SCRAPE_TIMEOUT_SECONDS).until(
                    EC.presence_of_element_located((By.CLASS_NAME, "a-price-whole"))
                )

                soup = BeautifulSoup(driver.page_source, "lxml")

                # Extract price
                price_el = soup.find("span", class_="a-price-whole")
                if not price_el:
                    raise ScraperException("Price element not found on Amazon page")
                price = extract_price_from_text(price_el.get_text())

                # Extract title
                title_el = soup.find("span", id="productTitle")
                title = title_el.get_text().strip() if title_el else "Unknown Product"

                # Extract image
                image_el = soup.find("img", id="landingImage")
                image_url = image_el.get("src", "") if image_el else ""

                result = {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "currency": "₹",
                    "platform": Platform.AMAZON.value,
                    "timestamp": datetime.now().isoformat(),
                    "url": url,
                }
                logger.info(f"Amazon scrape success: {title[:50]} = ₹{price}")
                return result

            except TimeoutException:
                logger.warning(f"Amazon timeout (attempt {attempt}/{retries})")
                if attempt == retries:
                    raise ScraperException("Timeout: Price element not found on Amazon")
                time.sleep(2 ** attempt)  # Exponential backoff
            except ScraperException:
                raise
            except Exception as e:
                logger.error(f"Amazon scrape error (attempt {attempt}): {e}")
                if attempt == retries:
                    raise ScraperException(f"Amazon scrape failed: {e}")
                time.sleep(2 ** attempt)
            finally:
                if driver:
                    try:
                        driver.quit()
                    except Exception:
                        pass

    def scrape_flipkart(self, url: str, retries: int = 3) -> Dict:
        """Scrape Flipkart product details with retry logic."""
        self._rate_limit()

        for attempt in range(1, retries + 1):
            driver = None
            try:
                logger.info(f"Scraping Flipkart (attempt {attempt}): {url[:80]}...")
                driver = self._get_chrome_driver()
                driver.get(url)

                WebDriverWait(driver, settings.SCRAPE_TIMEOUT_SECONDS).until(
                    EC.presence_of_element_located((By.CLASS_NAME, "_30jeq3"))
                )

                soup = BeautifulSoup(driver.page_source, "lxml")

                # Extract price ( ._30jeq3 class )
                price_el = soup.find("div", class_="_30jeq3")
                if not price_el:
                    raise ScraperException("Price element not found on Flipkart page")
                price = extract_price_from_text(price_el.get_text())

                # Extract title
                title_el = soup.find("span", class_="VU-ZEz") or soup.find(
                    "span", class_="B_NuCI"
                )
                title = (
                    title_el.get_text().strip() if title_el else "Unknown Product"
                )

                # Extract image
                image_el = soup.find("img", class_="_396cs4") or soup.find(
                    "img", class_="DByuf4"
                )
                image_url = image_el.get("src", "") if image_el else ""

                result = {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "currency": "₹",
                    "platform": Platform.FLIPKART.value,
                    "timestamp": datetime.now().isoformat(),
                    "url": url,
                }
                logger.info(f"Flipkart scrape success: {title[:50]} = ₹{price}")
                return result

            except TimeoutException:
                logger.warning(f"Flipkart timeout (attempt {attempt}/{retries})")
                if attempt == retries:
                    raise ScraperException("Timeout: Price element not found on Flipkart")
                time.sleep(2 ** attempt)
            except ScraperException:
                raise
            except Exception as e:
                logger.error(f"Flipkart scrape error (attempt {attempt}): {e}")
                if attempt == retries:
                    raise ScraperException(f"Flipkart scrape failed: {e}")
                time.sleep(2 ** attempt)
            finally:
                if driver:
                    try:
                        driver.quit()
                    except Exception:
                        pass

    def scrape_myntra(self, url: str, retries: int = 3) -> Dict:
        """Scrape Myntra product details."""
        self._rate_limit()

        for attempt in range(1, retries + 1):
            driver = None
            try:
                logger.info(f"Scraping Myntra (attempt {attempt}): {url[:80]}...")
                driver = self._get_chrome_driver()
                driver.get(url)

                # Myntra is a React app, wait for main container
                WebDriverWait(driver, settings.SCRAPE_TIMEOUT_SECONDS).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, "div.pdp-price"))
                )

                soup = BeautifulSoup(driver.page_source, "lxml")

                price_el = soup.select_one("div.pdp-price, span.pdp-price")
                if not price_el:
                    raise ScraperException("Price element not found on Myntra")
                price = extract_price_from_text(price_el.get_text())

                title_el = soup.select_one("h1.pdp-title")
                name_el = soup.select_one("h1.pdp-name")
                title = f"{title_el.get_text().strip() if title_el else ''} {name_el.get_text().strip() if name_el else ''}".strip() or "Unknown Myntra Product"

                image_el = soup.select_one("div.image-grid-image, div.image-grid-image img")
                image_url = ""
                if image_el:
                    image_url = image_el.get("style", "")
                    if "url(" in image_url:
                        image_url = image_url.split('url("')[1].split('")')[0]
                    else:
                        image_url = image_el.get("src", "")

                return {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "currency": "₹",
                    "platform": Platform.MYNTRA.value,
                    "timestamp": datetime.now().isoformat(),
                    "url": url,
                }
            except TimeoutException:
                if attempt == retries: raise ScraperException("Timeout: Myntra price not found")
                time.sleep(2 ** attempt)
            except Exception as e:
                if attempt == retries: raise ScraperException(f"Myntra scrape failed: {e}")
                time.sleep(2 ** attempt)
            finally:
                if driver:
                    try: driver.quit()
                    except Exception: pass

    def scrape_ebay(self, url: str, retries: int = 3) -> Dict:
        """Scrape eBay product details."""
        self._rate_limit()

        for attempt in range(1, retries + 1):
            driver = None
            try:
                logger.info(f"Scraping eBay (attempt {attempt}): {url[:80]}...")
                driver = self._get_chrome_driver()
                driver.get(url)

                WebDriverWait(driver, settings.SCRAPE_TIMEOUT_SECONDS).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, ".x-price-primary"))
                )

                soup = BeautifulSoup(driver.page_source, "lxml")

                price_el = soup.select_one(".x-price-primary")
                if not price_el:
                    raise ScraperException("Price element not found on eBay")
                price = extract_price_from_text(price_el.get_text())

                title_el = soup.select_one(".x-item-title__mainTitle span")
                title = title_el.get_text().strip() if title_el else "Unknown eBay Product"

                image_el = soup.select_one("img.ux-image-filmstrip-carousel-item.image") or soup.select_one(".ux-image-carousel img")
                image_url = image_el.get("src", "") if image_el else ""

                return {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "currency": "₹",
                    "platform": Platform.EBAY.value,
                    "timestamp": datetime.now().isoformat(),
                    "url": url,
                }
            except TimeoutException:
                if attempt == retries: raise ScraperException("Timeout: eBay price not found")
                time.sleep(2 ** attempt)
            except Exception as e:
                if attempt == retries: raise ScraperException(f"eBay scrape failed: {e}")
                time.sleep(2 ** attempt)
            finally:
                if driver:
                    try: driver.quit()
                    except Exception: pass


# Singleton
scraper_service = ScraperService()
