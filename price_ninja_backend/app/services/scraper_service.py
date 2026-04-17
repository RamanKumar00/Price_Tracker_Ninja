"""Web scraping service for Amazon.in and Flipkart.

Uses lightweight `requests` + BeautifulSoup as the primary scraper.
Falls back to Selenium with headless Chrome only if needed.
Includes rate limiting, retry logic, and user-agent rotation.
"""

import time
import random
import re
from datetime import datetime, timezone, timedelta
from typing import Dict, Optional

import requests
from bs4 import BeautifulSoup

from app.models import Platform, IST
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
    """Scrapes product prices from Amazon.in, Flipkart, Myntra, eBay.
    
    Uses requests+BS4 first (fast, no Chrome needed).
    Falls back to Selenium if available and requests fails.
    """

    def __init__(self):
        self._last_scrape_time: float = 0
        self._session = requests.Session()
        self._session.headers.update({
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
        })

    def _get_selenium_driver(self):
        """Initialize an optimized headless Chrome driver for low-RAM environments."""
        try:
            from selenium import webdriver
            from selenium.webdriver.chrome.options import Options
            
            options = Options()
            options.add_argument("--headless=new") # Faster headless mode
            options.add_argument("--no-sandbox")
            options.add_argument("--disable-dev-shm-usage")
            options.add_argument("--disable-gpu")
            options.add_argument("--disable-extensions")
            options.add_argument("--disable-notifications")
            options.add_argument("--blink-settings=imagesEnabled=false") # No images = fast
            options.add_argument("--window-size=1920,1080")
            options.add_argument(f"user-agent={random.choice(USER_AGENTS)}")
            
            # Optimization for Railway (low disk/RAM)
            options.add_argument("--disk-cache-dir=/tmp/chrome-cache")
            options.add_argument("--disk-cache-size=10485760") # 10MB limit
            
            return webdriver.Chrome(options=options)
        except Exception as e:
            logger.error(f"Failed to initialize Selenium: {e}")
            return None

    def _scrape_with_selenium(self, url: str, price_selector: str, title_selector: str, img_selector: str) -> Dict:
        """Fallback method using Selenium for JS-heavy or protected sites."""
        driver = self._get_selenium_driver()
        if not driver:
            return {}
        
        try:
            logger.info(f"Selenium fallback for: {url[:60]}")
            driver.get(url)
            time.sleep(5) # Wait for JS to render
            
            from selenium.webdriver.common.by import By
            
            # Try to get price
            price = None
            try:
                price_text = driver.find_element(By.CSS_SELECTOR, price_selector).text
                price = extract_price_from_text(price_text)
            except: pass

            # Try to get title
            title = "Unknown Product"
            try:
                title = driver.find_element(By.CSS_SELECTOR, title_selector).text.strip()
            except: pass

            # Try to get image
            image_url = ""
            try:
                img_el = driver.find_element(By.CSS_SELECTOR, img_selector)
                image_url = img_el.get_attribute("src") or img_el.get_attribute("data-src")
            except: pass

            if price:
                return {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "timestamp": datetime.now(IST).isoformat(),
                }
            return {}
        except Exception as e:
            logger.warning(f"Selenium scrape failed: {e}")
            return {}
        finally:
            driver.quit()

    def _rate_limit(self):
        """Enforce minimum delay between scrape requests."""
        elapsed = time.time() - self._last_scrape_time
        min_delay = 1.0
        wait = min_delay - elapsed
        if wait > 0:
            time.sleep(wait)
        self._last_scrape_time = time.time()

    def _get_headers(self) -> dict:
        """Get request headers with a random User-Agent."""
        return {"User-Agent": random.choice(USER_AGENTS)}

    def _fetch_page(self, url: str, timeout: int = 15) -> BeautifulSoup:
        """Fetch a page using requests and return BeautifulSoup object."""
        headers = self._get_headers()
        try:
            response = self._session.get(url, headers=headers, timeout=timeout)
            response.raise_for_status()
            # If we get a 200 but it's an "Are you a human?" page
            if "captcha" in response.text.lower() or "robot" in response.text.lower():
                logger.warning(f"Detected CAPTCHA/Bot protection on {url}")
                return BeautifulSoup(response.text, "lxml") # Still return to check
            return BeautifulSoup(response.text, "lxml")
        except Exception as e:
            raise ScraperException(f"Request failed: {e}")

    def scrape(self, url: str) -> Dict:
        """Entry point for scraping with global retry mechanism."""
        max_retries = 3
        last_error = "Unknown error"

        for attempt in range(1, max_retries + 1):
            try:
                platform = detect_platform(url)
                logger.info(f"Attempt {attempt}/{max_retries} for {platform.value}: {url[:60]}")
                
                if platform == Platform.AMAZON:
                    res = self.scrape_amazon(url)
                elif platform == Platform.FLIPKART:
                    res = self.scrape_flipkart(url)
                elif platform == Platform.MYNTRA:
                    res = self.scrape_myntra(url)
                elif platform == Platform.EBAY:
                    res = self.scrape_ebay(url)
                else:
                    res = self.scrape_generic(url)
                
                if res and res.get("price"):
                    return res
                
                last_error = "Price not found in response"
                
            except Exception as e:
                last_error = str(e)
                logger.warning(f"Attempt {attempt} failed: {e}")
            
            if attempt < max_retries:
                # Exponential backoff + jitter
                sleep_time = (2 ** attempt) + random.uniform(0, 2)
                logger.info(f"Retrying in {sleep_time:.1f}s...")
                time.sleep(sleep_time)

        raise ScraperException(f"Failed after {max_retries} attempts. Last error: {last_error}")


    def scrape_amazon(self, url: str, retries: int = 1) -> Dict:
        """Scrape Amazon.in product details with retry logic."""
        self._rate_limit()

        for attempt in range(1, retries + 1):
            try:
                logger.info(f"Scraping Amazon (attempt {attempt}): {url[:80]}...")
                soup = self._fetch_page(url)

                # ─── Extract price ───
                price = None

                # Method 1: a-price-whole (most common)
                price_el = soup.find("span", class_="a-price-whole")
                if price_el:
                    price = extract_price_from_text(price_el.get_text())

                # Method 2: a-price span
                if price is None:
                    price_el = soup.find("span", class_="a-price")
                    if price_el:
                        inner = price_el.find("span", class_="a-offscreen")
                        if inner:
                            price = extract_price_from_text(inner.get_text())

                # Method 3: priceblock_dealprice or priceblock_ourprice
                if price is None:
                    for pid in ["priceblock_dealprice", "priceblock_ourprice", "price_inside_buybox"]:
                        el = soup.find("span", id=pid)
                        if el:
                            price = extract_price_from_text(el.get_text())
                            break

                # Method 4: corePriceDisplay
                if price is None:
                    core_price = soup.select_one("div#corePriceDisplay_desktop_feature_div span.a-offscreen")
                    if core_price:
                        price = extract_price_from_text(core_price.get_text())

                if price is None:
                    if attempt == retries:
                        raise ScraperException("Price element not found on Amazon page")
                    time.sleep(2 ** attempt)
                    continue

                # ─── Extract title ───
                title_el = soup.find("span", id="productTitle")
                title = title_el.get_text().strip() if title_el else "Unknown Product"

                # ─── Extract image ───
                image_url = ""
                
                # Check meta tags first (fast and reliable for primary image)
                og_img = soup.find("meta", property="og:image") or soup.find("meta", attrs={"name": "twitter:image"})
                if og_img:
                    image_url = og_img.get("content", "")

                if not image_url:
                    image_el = (soup.find("img", id="landingImage") or 
                                soup.find("img", id="main-image") or 
                                soup.find("img", id="imgBlkFront") or 
                                soup.find("img", id="ebooksImgBlkFront"))
                    if image_el:
                        # Amazon dynamic image JSON parsing
                        dynamic_img = image_el.get("data-a-dynamic-image", "")
                        if dynamic_img and "{" in dynamic_img:
                            try:
                                import json
                                img_map = json.loads(dynamic_img)
                                # Pick the largest image (usually the one with highest resolution)
                                # The keys are URLs, values are [width, height]
                                image_url = max(img_map.keys(), key=lambda k: img_map[k][0] * img_map[k][1])
                            except:
                                pass
                        
                        if not image_url:
                            image_url = image_el.get("data-old-hires", "") or image_el.get("src", "") or image_el.get("data-src", "")
                
                if not image_url:
                    # Fallback: look in gallery
                    gallery_img = soup.select_one("img.a-dynamic-image") or soup.select_one("#altImages img")
                    if gallery_img:
                        image_url = gallery_img.get("src", "") or gallery_img.get("data-src", "")

                # Clean and ensure absolute
                if image_url:
                    if image_url.startswith("//"):
                        image_url = "https:" + image_url
                    elif image_url.startswith("/"):
                        image_url = "https://www.amazon.in" + image_url

                # ─── Extract description ───
                desc_meta = soup.find("meta", attrs={"name": re.compile(r"description", re.I)}) or soup.find("meta", attrs={"property": re.compile(r"og:description", re.I)})
                description = desc_meta.get("content", "").strip() if desc_meta else "No description available for this product."

                result = {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "description": description,
                    "currency": "₹",
                    "platform": Platform.AMAZON.value,
                    "timestamp": datetime.now(IST).isoformat(),
                    "url": url,
                }
                logger.info(f"Amazon scrape success: {title[:50]} = ₹{price}")
                return result

            except ScraperException:
                if attempt == retries:
                    raise
                time.sleep(2 ** attempt)
            except Exception as e:
                logger.error(f"Amazon scrape error (attempt {attempt}): {e}")
                if price is None:
                    # Look for data-a-dynamic-image for better original quality image
                    img_div = soup.find("div", id="imgTagWrapperId")
                    if img_div:
                        img_tag = img_div.find("img")
                        if img_tag and img_tag.get("data-a-dynamic-image"):
                            try:
                                import json
                                dynamic_imgs = json.loads(img_tag.get("data-a-dynamic-image"))
                                image_url = list(dynamic_imgs.keys())[0] if dynamic_imgs else image_url
                            except: pass
                
                # FINAL FALLBACK: Selenium (If we have no price or title)
                if price is None or title == "Unknown Product":
                    sel_res = self._scrape_with_selenium(
                        url, 
                        price_selector=".a-price-whole, #priceblock_ourprice, #priceblock_dealprice", 
                        title_selector="#productTitle", 
                        img_selector="#landingImage"
                    )
                    if sel_res:
                        return sel_res

                if not price or not title:
                    raise ScraperException("Could not extract Amazon product data")
                time.sleep(2 ** attempt)

    def scrape_flipkart(self, url: str, retries: int = 1) -> Dict:
        """Scrape Flipkart product details with retry logic."""
        self._rate_limit()

        # Flipkart often blocks desktop scrapers but allows mobile ones more easily
        mobile_headers = {
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_8 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-IN,en;q=0.9",
        }

        for attempt in range(1, retries + 1):
            try:
                logger.info(f"Scraping Flipkart (attempt {attempt}): {url[:80]}...")
                
                # Try with mobile headers first
                response = self._session.get(url, headers=mobile_headers, timeout=10)
                soup = BeautifulSoup(response.text, "lxml")

                # ─── Extract price ───
                price = None

                # Method 1: meta tags (Reliable on mobile/desktop both)
                meta_price = (soup.find("meta", {"property": "product:price:amount"}) or 
                              soup.find("meta", {"name": "twitter:data1"})) # twitter:data1 is often price on FK
                if meta_price:
                    try:
                        content = meta_price.get("content", "") or meta_price.get("value", "")
                        price = extract_price_from_text(content)
                    except: pass

                # Method 2: div with specifically named classes (Nx9bqj is current)
                if price is None:
                    price_el = soup.find("div", class_="Nx9bqj") or soup.find("div", class_="_30jeq3")
                    if price_el:
                        price = extract_price_from_text(price_el.get_text())

                # Method 3: structured data JSON-LD
                if price is None:
                    script = soup.find("script", {"type": "application/ld+json"})
                    if script:
                        try:
                            import json
                            data = json.loads(script.string)
                            if isinstance(data, list): data = data[0]
                            price = float(data["offers"]["price"])
                        except: pass

                if price is None:
                    # Generic selector
                    p_tag = soup.find("div", string=re.compile(r"₹\d+"))
                    if p_tag:
                        price = extract_price_from_text(p_tag.get_text())

                # FINAL FALLBACK: Selenium
                if price is None or title == "Unknown Product":
                    sel_res = self._scrape_with_selenium(
                        url, 
                        price_selector="._30jeq3, ._25b18c ._30jeq3", 
                        title_selector=".B_NuCI", 
                        img_selector="._396cs4, ._2r_T1_"
                    )
                    if sel_res:
                        return sel_res

                if not price or not title:
                    raise ScraperException("Could not extract Flipkart product data")
                    time.sleep(2)
                    continue

                # ─── Extract title ───
                title = "Unknown Product"
                og_title = soup.find("meta", property="og:title")
                if og_title:
                    title = og_title.get("content", "").strip()
                
                if title == "Unknown Product" or not title:
                    for cls in ["VU-ZEz", "B_NuCI", "yhB1nd"]:
                        el = soup.find("span", class_=cls)
                        if el:
                            title = el.get_text().strip()
                            break

                # ─── Extract image ───
                image_url = ""
                og_img = soup.find("meta", property="og:image") or soup.find("meta", attrs={"name": "twitter:image"})
                if og_img:
                    image_url = og_img.get("content", "")

                if not image_url:
                    img_el = soup.find("img", class_="_396cs4") or soup.find("img", class_="DByuf4")
                    if img_el:
                        image_url = img_el.get("src", "") or img_el.get("data-src", "")

                # Clean and ensure absolute
                if image_url:
                    if image_url.startswith("//"):
                        image_url = "https:" + image_url
                    elif image_url.startswith("/"):
                        image_url = "https://www.flipkart.com" + image_url

                description = "No description available."
                desc_meta = soup.find("meta", attrs={"name": "description"})
                if desc_meta:
                    description = desc_meta.get("content", "").strip()

                result = {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "description": description,
                    "currency": "₹",
                    "platform": Platform.FLIPKART.value,
                    "timestamp": datetime.now(IST).isoformat(),
                    "url": url,
                }
                logger.info(f"Flipkart scrape success: {title[:40]} = ₹{price}")
                return result

            except ScraperException:
                if attempt == retries:
                    raise
                time.sleep(2 ** attempt)
            except Exception as e:
                logger.error(f"Flipkart scrape error (attempt {attempt}): {e}")
                if attempt == retries:
                    raise ScraperException(f"Flipkart scrape failed: {e}")
                time.sleep(2 ** attempt)

    def scrape_myntra(self, url: str, retries: int = 1) -> Dict:
        """Scrape Myntra product details."""
        self._rate_limit()

        for attempt in range(1, retries + 1):
            try:
                logger.info(f"Scraping Myntra (attempt {attempt}): {url[:80]}...")
                soup = self._fetch_page(url)

                # ─── Extract price ───
                price = None
                price_el = soup.select_one("div.pdp-price, span.pdp-price")
                if price_el:
                    price = extract_price_from_text(price_el.get_text())

                # Fallback: pdp-discount-container
                if price is None:
                    pdp = soup.select_one("span.pdp-discountedPrice, span.pdp-mrp")
                    if pdp:
                        price = extract_price_from_text(pdp.get_text())

                # Fallback: script data (Myntra SSR)
                if price is None:
                    scripts = soup.find_all("script")
                    for s in scripts:
                        text = s.string or ""
                        if '"price":' in text:
                            m = re.search(r'"price"\s*:\s*([\d.]+)', text)
                            if m:
                                price = float(m.group(1))
                                break

                if price is None:
                    if attempt == retries:
                        raise ScraperException("Price element not found on Myntra")
                    time.sleep(2 ** attempt)
                    continue

                # ─── Title ───
                title_el = soup.select_one("h1.pdp-title")
                name_el = soup.select_one("h1.pdp-name")
                title = f"{title_el.get_text().strip() if title_el else ''} {name_el.get_text().strip() if name_el else ''}".strip() or "Unknown Myntra Product"

                # ─── Image ───
                image_url = ""
                og = soup.find("meta", {"property": "og:image"})
                if og:
                    image_url = og.get("content", "")

                # ─── Description ───
                desc_meta = soup.find("meta", attrs={"name": re.compile(r"description", re.I)}) or soup.find("meta", attrs={"property": re.compile(r"og:description", re.I)})
                description = desc_meta.get("content", "").strip() if desc_meta else "No description available for this product."

                return {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "description": description,
                    "currency": "₹",
                    "platform": Platform.MYNTRA.value,
                    "timestamp": datetime.now(IST).isoformat(),
                    "url": url,
                }
            except ScraperException:
                if attempt == retries:
                    raise
                time.sleep(2 ** attempt)
            except Exception as e:
                if attempt == retries:
                    raise ScraperException(f"Myntra scrape failed: {e}")
                time.sleep(2 ** attempt)

    def scrape_ebay(self, url: str, retries: int = 1) -> Dict:
        """Scrape eBay product details."""
        self._rate_limit()

        for attempt in range(1, retries + 1):
            try:
                logger.info(f"Scraping eBay (attempt {attempt}): {url[:80]}...")
                soup = self._fetch_page(url)

                # ─── Price ───
                price = None
                price_el = soup.select_one(".x-price-primary")
                if price_el:
                    price = extract_price_from_text(price_el.get_text())

                if price is None:
                    # Fallback: itemprop=price
                    meta = soup.find("meta", {"itemprop": "price"})
                    if meta:
                        price = float(meta.get("content", "0"))

                if price is None:
                    if attempt == retries:
                        raise ScraperException("Price element not found on eBay")
                    time.sleep(2 ** attempt)
                    continue

                # ─── Title ───
                title_el = soup.select_one(".x-item-title__mainTitle span")
                if not title_el:
                    title_el = soup.find("h1", {"id": "itemTitle"})
                title = title_el.get_text().strip() if title_el else "Unknown eBay Product"

                # ─── Image ───
                image_el = soup.select_one("img.ux-image-filmstrip-carousel-item.image") or soup.select_one(".ux-image-carousel img")
                image_url = image_el.get("src", "") if image_el else ""

                # ─── Description ───
                desc_meta = soup.find("meta", attrs={"name": re.compile(r"description", re.I)}) or soup.find("meta", attrs={"property": re.compile(r"og:description", re.I)})
                description = desc_meta.get("content", "").strip() if desc_meta else "No description available for this product."

                return {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "description": description,
                    "currency": "₹",
                    "platform": Platform.EBAY.value,
                    "timestamp": datetime.now(IST).isoformat(),
                    "url": url,
                }
            except ScraperException:
                if attempt == retries:
                    raise
                time.sleep(2 ** attempt)
            except Exception as e:
                if attempt == retries:
                    raise ScraperException(f"eBay scrape failed: {e}")
                time.sleep(2 ** attempt)

    def scrape_generic(self, url: str, retries: int = 2) -> Dict:
        """Generic scraper for any e-commerce site.
        
        Extracts title from og:title/<title>, price from meta/JSON-LD/structured data,
        and image from og:image. Works as a best-effort fallback.
        """
        self._rate_limit()

        for attempt in range(1, retries + 1):
            try:
                logger.info(f"Generic scrape (attempt {attempt}): {url[:80]}...")
                soup = self._fetch_page(url)

                # ─── Title ───
                title = "Unknown Product"
                og_title = soup.find("meta", {"property": "og:title"})
                if og_title:
                    title = og_title.get("content", "").strip()
                if title == "Unknown Product":
                    title_tag = soup.find("title")
                    if title_tag:
                        title = title_tag.get_text().strip()

                # ─── Price ───
                price = None

                # Method 1: product:price:amount meta tag
                meta_price = soup.find("meta", {"property": "product:price:amount"})
                if meta_price:
                    try:
                        price = float(meta_price.get("content", "0"))
                    except ValueError:
                        pass

                # Method 2: itemprop="price"
                if price is None:
                    itemprop = soup.find(attrs={"itemprop": "price"})
                    if itemprop:
                        content = itemprop.get("content", "") or itemprop.get_text()
                        try:
                            price = extract_price_from_text(content)
                        except ValueError:
                            pass

                # Method 3: JSON-LD structured data
                if price is None:
                    scripts = soup.find_all("script", {"type": "application/ld+json"})
                    for s in scripts:
                        try:
                            import json
                            data = json.loads(s.string or "{}")
                            if isinstance(data, list):
                                data = data[0] if data else {}
                            # Look for offers.price
                            offers = data.get("offers", {})
                            if isinstance(offers, list):
                                offers = offers[0] if offers else {}
                            p = offers.get("price")
                            if p:
                                price = float(p)
                                break
                        except (json.JSONDecodeError, ValueError, TypeError):
                            pass

                # Method 4: Find any element with ₹ text
                if price is None:
                    for tag in soup.find_all(["span", "div", "p"], string=re.compile(r"₹\s*[\d,]+")):
                        try:
                            price = extract_price_from_text(tag.get_text())
                            break
                        except ValueError:
                            continue

                # ─── Image ───
                image_url = ""
                og_img = soup.find("meta", {"property": "og:image"})
                if og_img:
                    image_url = og_img.get("content", "")

                # ─── Detect platform name from domain ───
                from urllib.parse import urlparse
                domain = urlparse(url).netloc.replace("www.", "")
                platform_name = domain.split(".")[0].capitalize()

                # ─── Description ───
                desc_meta = soup.find("meta", attrs={"name": re.compile(r"description", re.I)}) or soup.find("meta", attrs={"property": re.compile(r"og:description", re.I)})
                description = desc_meta.get("content", "").strip() if desc_meta else "No description available for this product."

                result = {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "description": description,
                    "currency": "₹",
                    "platform": platform_name,
                    "timestamp": datetime.now(IST).isoformat(),
                    "url": url,
                }

                if price:
                    logger.info(f"Generic scrape success: {title[:50]} = ₹{price}")
                else:
                    logger.warning(f"Generic scrape: got title but no price for {url[:60]}")

                return result

            except ScraperException:
                if attempt == retries:
                    raise
                time.sleep(2 ** attempt)
            except Exception as e:
                if attempt == retries:
                    raise ScraperException(f"Generic scrape failed: {e}")
                time.sleep(2 ** attempt)


# Singleton
scraper_service = ScraperService()
