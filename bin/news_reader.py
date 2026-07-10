#!/usr/bin/env python3
"""
UK News CLI Reader
A simple command-line RSS news reader with UK-focused sources
"""

import feedparser
import sys
from datetime import datetime
import textwrap

# UK-focused RSS feeds by category
RSS_FEEDS = {
    "news": [
        ("BBC News", "http://feeds.bbci.co.uk/news/rss.xml"),
        ("The Guardian", "https://www.theguardian.com/uk/rss"),
        ("Sky News", "https://feeds.skynews.com/feeds/rss/home.xml"),
        ("The Telegraph", "https://www.telegraph.co.uk/rss.xml"),
    ],
    "technology": [
        ("BBC Technology", "http://feeds.bbci.co.uk/news/technology/rss.xml"),
        ("The Register", "https://www.theregister.com/headlines.atom"),
        ("Ars Technica UK", "https://feeds.arstechnica.com/arstechnica/technology-lab"),
        ("TechRadar", "https://www.techradar.com/rss"),
    ],
    "business": [
        ("BBC Business", "http://feeds.bbci.co.uk/news/business/rss.xml"),
        ("Financial Times", "https://www.ft.com/?format=rss"),
        ("City AM", "https://www.cityam.com/feed/"),
    ],
    "sports": [
        ("BBC Sport", "http://feeds.bbci.co.uk/sport/rss.xml"),
        ("Sky Sports", "https://www.skysports.com/rss/12040"),
        ("The Guardian Sport", "https://www.theguardian.com/uk/sport/rss"),
    ],
    "entertainment": [
        ("BBC Entertainment", "http://feeds.bbci.co.uk/news/entertainment_and_arts/rss.xml"),
        ("Digital Spy", "https://www.digitalspy.com/rss"),
        ("NME", "https://www.nme.com/feed"),
    ],
    "linux": [
        ("OMG! Ubuntu", "https://www.omgubuntu.co.uk/feed"),
        ("Linux Magazine", "https://www.linux-magazine.com/rss/feed/lmi_full"),
        ("Phoronix", "https://www.phoronix.com/rss.php"),
        ("It's FOSS", "https://itsfoss.com/rss/"),
    ],
    "gaming": [
        ("Eurogamer", "https://www.eurogamer.net/?format=rss"),
        ("Rock Paper Shotgun", "https://www.rockpapershotgun.com/feed"),
        ("PC Gamer", "https://www.pcgamer.com/rss/"),
        ("VG247", "https://www.vg247.com/feed"),
    ],
}


def print_header(text):
    """Print a formatted header"""
    width = 80
    print("\n" + "=" * width)
    print(f" {text.upper()}")
    print("=" * width)


def print_article(index, title, link, published, source):
    """Print a single article with formatting"""
    print(f"\n[{index}] {source}")
    print(f"    {title}")
    if published:
        print(f"    Published: {published}")
    print(f"    Link: {link}")


def fetch_category_news(category, max_per_source=5):
    """Fetch news for a specific category"""
    if category not in RSS_FEEDS:
        print(f"Category '{category}' not found!")
        return []

    articles = []
    feeds = RSS_FEEDS[category]

    for source_name, feed_url in feeds:
        try:
            print(f"Fetching from {source_name}...", file=sys.stderr)
            feed = feedparser.parse(feed_url)
            
            for entry in feed.entries[:max_per_source]:
                published = entry.get('published', 'Unknown date')
                articles.append({
                    'source': source_name,
                    'title': entry.get('title', 'No title'),
                    'link': entry.get('link', ''),
                    'published': published,
                })
        except Exception as e:
            print(f"Error fetching {source_name}: {e}", file=sys.stderr)

    return articles


def display_menu():
    """Display category menu"""
    print_header("UK News Reader")
    print("\nAvailable categories:")
    for i, category in enumerate(RSS_FEEDS.keys(), 1):
        print(f"  {i}. {category.capitalize()}")
    print(f"  {len(RSS_FEEDS) + 1}. All categories")
    print("  0. Exit")


def main():
    """Main application loop"""
    while True:
        display_menu()
        
        try:
            choice = input("\nSelect category (number): ").strip()
            
            if choice == "0":
                print("\nGoodbye!")
                sys.exit(0)
            
            choice_num = int(choice)
            categories = list(RSS_FEEDS.keys())
            
            if choice_num == len(RSS_FEEDS) + 1:
                # All categories
                selected_categories = categories
            elif 1 <= choice_num <= len(RSS_FEEDS):
                selected_categories = [categories[choice_num - 1]]
            else:
                print("Invalid choice!")
                continue
            
            # Fetch and display news
            all_articles = []
            for cat in selected_categories:
                print_header(cat)
                articles = fetch_category_news(cat, max_per_source=5)
                all_articles.extend(articles)
                
                for i, article in enumerate(articles, 1):
                    print_article(
                        i,
                        article['title'],
                        article['link'],
                        article['published'],
                        article['source']
                    )
            
            # Ask if user wants to open a link
            print("\n" + "-" * 80)
            open_link = input("\nOpen link? (enter number or press Enter to continue): ").strip()
            
            if open_link and open_link.isdigit():
                link_num = int(open_link)
                if 1 <= link_num <= len(all_articles):
                    import webbrowser
                    webbrowser.open(all_articles[link_num - 1]['link'])
                    print(f"Opening link in browser...")
                else:
                    print("Invalid article number!")
            
            input("\nPress Enter to continue...")
            
        except ValueError:
            print("Please enter a valid number!")
        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            sys.exit(0)


if __name__ == "__main__":
    main()
