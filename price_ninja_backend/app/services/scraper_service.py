"""Web scraping service for Amazon.in and Flipkart.

Uses lightweight `requests` + BeautifulSoup as the primary scraper.
Falls back to Selenium with headless Chrome only if needed.
Includes rate limiting, retry logic, and user-agent rotation.
"""

import time
import random
import re
from datetime import datetime
from typing import Dict, Optional

import requests
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
    """Scrapes product prices from Amazon.in, Flipkart, Myntra, eBay.
    
    Uses requests+BS4 first (fast, no Chrome needed).
    Falls back to Selenium if available and requests fails.
    """

    def __init__(self):
        self._last_scrape_time: float = 0
        self._session = requests.Session()
        self._session.headers.update({
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9,hi;q=0.8",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Cache-Control": "max-age=0",
        })

    def _rate_limit(self):
        """Enforce minimum delay between scrape requests."""
        elapsed = time.time() - self._last_scrape_time
        min_delay = 0.5  # Fast for initial add; scheduled scrapes can be slower
        wait = min_delay - elapsed
        if wait > 0:
            time.sleep(wait)
        self._last_scrape_time = time.time()

    def _get_headers(self) -> dict:
        """Get request headers with a random User-Agent."""
        return {"User-Agent": random.choice(USER_AGENTS)}

    def _fetch_page(self, url: str, timeout: int = 10) -> BeautifulSoup:
        """Fetch a page using requests and return BeautifulSoup object."""
        headers = self._get_headers()
        try:
            response = self._session.get(
                url,
                headers=headers,
                timeout=timeout,
                allow_redirects=True,
            )
            response.raise_for_status()
            return BeautifulSoup(response.text, "lxml")
        except requests.exceptions.Timeout:
            raise ScraperException(f"Request timed out for {url}")
        except requests.exceptions.ConnectionError:
            raise ScraperException(f"Connection failed for {url}")
        except requests.exceptions.HTTPError as e:
            raise ScraperException(f"HTTP error {e.response.status_code} for {url}")
        except Exception as e:
            raise ScraperException(f"Request failed: {e}")

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
                image_el = soup.find("img", id="landingImage")
                if image_el:
                    image_url = image_el.get("data-old-hires", "") or image_el.get("src", "")
                if not image_url:
                    # Fallback: look in image block
                    img_block = soup.find("img", {"data-image-index": "0"})
                    if img_block:
                        image_url = img_block.get("src", "")

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

            except ScraperException:
                if attempt == retries:
                    raise
                time.sleep(2 ** attempt)
            except Exception as e:
                logger.error(f"Amazon scrape error (attempt {attempt}): {e}")
                if attempt == retries:
                    raise ScraperException(f"Amazon scrape failed: {e}")
                time.sleep(2 ** attempt)

    def scrape_flipkart(self, url: str, retries: int = 1) -> Dict:
        """Scrape Flipkart product details with retry logic."""
        self._rate_limit()

        for attempt in range(1, retries + 1):
            try:
                logger.info(f"Scraping Flipkart (attempt {attempt}): {url[:80]}...")
                soup = self._fetch_page(url)

                # ─── Extract price ───
                price = None

                # Method 1: _30jeq3 class (classic)
                price_el = soup.find("div", class_="_30jeq3")
                if price_el:
                    price = extract_price_from_text(price_el.get_text())

                # Method 2: Cfs16oy class (new layout)
                if price is None:
                    price_el = soup.find("div", class_="Nx9bqj CxhGGd")
                    if price_el:
                        price = extract_price_from_text(price_el.get_text())

                # Method 3: Any div with ₹ in specific selectors
                if price is None:
                    price_el = soup.select_one("div.Nx9bqj")
                    if price_el:
                        price = extract_price_from_text(price_el.get_text())

                # Method 4: meta tag
                if price is None:
                    meta = soup.find("meta", {"property": "product:price:amount"})
                    if meta:
                        price = float(meta.get("content", "0"))

                if price is None:
                    if attempt == retries:
                        raise ScraperException("Price element not found on Flipkart page")
                    time.sleep(2 ** attempt)
                    continue

                # ─── Extract title ───
                title = "Unknown Product"
                for cls in ["VU-ZEz", "B_NuCI", "yhB1nd"]:
                    title_el = soup.find("span", class_=cls)
                    if title_el:
                        title = title_el.get_text().strip()
                        break
                if title == "Unknown Product":
                    title_el = soup.find("h1", class_="yhB1nd")
                    if title_el:
                        title = title_el.find("span")
                        title = title.get_text().strip() if title else "Unknown Product"

                # ─── Extract image ───
                image_url = ""
                for cls in ["_396cs4", "DByuf4", "_2r_T1I"]:
                    image_el = soup.find("img", class_=cls)
                    if image_el:
                        image_url = image_el.get("src", "")
                        break
                if not image_url:
                    # Fallback: og:image
                    og = soup.find("meta", {"property": "og:image"})
                    if og:
                        image_url = og.get("content", "")

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

                return {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "currency": "₹",
                    "platform": Platform.MYNTRA.value,
                    "timestamp": datetime.now().isoformat(),
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

                return {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "currency": "₹",
                    "platform": Platform.EBAY.value,
                    "timestamp": datetime.now().isoformat(),
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

                result = {
                    "price": price,
                    "title": title,
                    "image_url": image_url,
                    "currency": "₹",
                    "platform": platform_name,
                    "timestamp": datetime.now().isoformat(),
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
