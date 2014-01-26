Project Baker
=============

**The HTML5 ebook framework to publish interactive books & magazines on iPad & iPhone using simply open web standards**
<http://bakerframework.com>



WHAT IS BAKER
-------------

To this day, ebooks have been limited by an old standard created in the pre-Kindle and pre-iPad era.
Baker is the first stepping stone to show that we could already be using the powerful HTML5 language
to create books with real typography, real layouts and high-quality design.



HOW TO USE BAKER
----------------

Creating an ebook in HTML5 to be used with Baker is a three-steps operation.
It's easier done than said! ;)

1. DESIGN
   * Create you publication as one or more **HTML5 files** like a standalone website
   * Design your publication to fit multiple screen (using CSS media-queries)
   * You can use **any** feature in WebKit: HTML5, CSS3, JavaScript (video, audio, fonts, jQuery, Google Maps, etc)
   * On iPad/iPhone you can constrain the height to match the page size or make it scrollable if you need longer pages
   * For best results, consider having 1 HTML for each chapter/section/article and use the native vertical scrolling.
   * ...remember: it's a publication. If you want to build an app, check [PhoneGap](http://www.phonegap.com/). ;)

2. PACKAGE
   * The publication must be contained in a single Hpub file
   * Each chapter/section/article (horizontally swiped on the iPad) should be a single HTML file inside the Hpub
   * Create a Hpub book.json file: title, author, pages, etc. (see below)
   * All the assets must be contained within the publication folder or its subfolders
   * Check the example book from the website for an hands-on example
   * See either [Standalone tutorial](https://github.com/bakerframework/baker/wiki/Tutorial-for-Standalone-App) or [Newsstand tutorial for free subscriptions](https://github.com/bakerframework/baker/wiki/Tutorial-for-Newsstand-with-Free-issues) or [Newsstand tutorial for paid subscriptions](https://github.com/bakerframework/baker/wiki/Tutorial-for-Newsstand-with-In-App-Purchase) for more information

3. PUBLISH
   * Download the Baker Framework Xcode project from http://bakerframework.com (or GitHub).
   * Download Xcode from the Mac App Store or from the Apple Developer website.
   * Decide if you want to release using the [Standalone tutorial](https://github.com/bakerframework/baker/wiki/Tutorial-for-Standalone-App) or [Newsstand tutorial](https://github.com/bakerframework/baker/wiki/Tutorial-for-Newsstand-with-Free-issues) mode and follow the tutorial accordingly.
   * Select the Baker Scheme (Simulator or Device) from the toolbar dropdown.
   * Run and check that everything works correctly _both_ on simulator and device.
   * Check [this page](https://github.com/bakerframework/baker/wiki/Problems-and-Debugging) if you encounter any problem.
   * Create an Apple iPhone Developer account to publish on the App Store.
   * If you are using Newsstand, follow the instructions on the Apple iPhone Developer website to create either your free subscription or paid subscription / issue In App Purchases
   * Follow the instructions on the Apple iPhone Developer website to submit your book to the app store.


BOOK.JSON
---------

This is an example of a minimal book.json file:

```json
{
  "title": "The Study in Scarlet",
  "author": "Arthur Conan Doyle",
  "url": "book://bakerframework.com/books/arthurconandoyle-thestudyinscarlet",

  "contents": [
    "Article-Lorem.html",
    "Article-Ipsum.html",
    "Article-Gaium.html",
    "Article-Sit.html",
    "Article-Amet.html"
  ]
}
```

For all the details and the advanced options, check the [Hpub specification on the wiki](https://github.com/bakerframework/baker/wiki/hpub-specification).


SHELF.JSON
----------

This is an example of the shelf.json file that is downloaded by Baker in Newsstand mode to check the available publications:

```json
[
  {
    "name": "a-study-in-scarlet",
    "title": "A Study in Scarlet",
    "info": "The original masterpiece by Sir Arthur Conan Doyle",
    "date": "1887-10-10 10:10:10",
    "cover": "http://bakerframework.com/newsstand-books/a-study-in-scarlet.png",
    "url": "http://bakerframework.com/newsstand-books/a-study-in-scarlet.hpub",
    "product_id": "com.bakerframework.Baker.issues.a_study_in_scarlet"
  }
]
```

For all the details on how to create and use it, check the [Newsstand publications](https://github.com/bakerframework/baker/wiki/4.0-tutorial-for-Newsstand).


CREATE A BOOK FOR BOTH IPAD AND IPHONE
--------------------------------------

With Baker Framework you can create books and magazines for the iPhone too.

To compile your application for iPhone follow these steps:

* Open the Baker Framework Xcode project with Xcode.
* Click on the "Baker" project in the leftmost column of the project navigator.
* On the column just left, click under Projects on "Baker"
* In the "Build Settings" tab locate the section Deployment for the configuration you would like to use for compiling.
* Under the Deployment section change the Target Device Family entry to match the devices you would like to target (only iPhone, only iPad or iPhone/iPad).
* Update your publications to manage multiple orientations (using CSS media-queries).
* Compile and test the application.



BUGS AND FEEDBACK
-----------------

* Submit your bugs here: <http://github.com/bakerframework/baker/issues>
* Give us your feedback at: <info@bakerframework.com>
* Follow us on Twitter: <http://twitter.com/BakerFramework>



CHANGELOG
---------
* **4.2.1** (26/01/2014)
  * Branding changes.  New Baker Framework logo assets
  * Open local files in modal view.  Action button not shown.  Useful if you have local documents (html, pdf, etc...) related to the content of your Baker HPub
  * Bugfixes related to iOS 7 app validation (Asset Catalog Errors)
  
* **4.2** (28/10/2013)
  * iOS 7 support
  * Text Kit support
  * Support for analytics/tracking frameworks
  * Info box in shelf
  * `init` JS event for Info box with `user_id` and `app_id`
  * Asset Catalog support
  * Added `environment` parameter to Baker API calls
  * Made most remote calls asynchronous
  * Support for removing issues from `shelf.json`
  * Replaced AQGridView with UICollectionView
  * Minor improvements and bugfixes

* **4.1** (06/05/2013)
  * In-App Purchases for your magazine issues (server required)
  * Paid Subscriptions support (server required)
  * Push notifications capabilit (server required)
  * Baker API defined to allow third-party servers
  * Vertical pagination flexibility with `<meta name="paged" content="YES">`
  * Issue data can now be refreshed
  * book: protocol now works within the issues on the shelf
  * Index handling improvements
  * Removed JSONKit, using iOS5+ parser
  * Memory enhancements
  * Cleaned up the debug console log and error messages
  * Bugs and fixes

* **4.0** (22/12/2012)
  * Full Newsstand support
  * Shelf to manage multiple publications
  * Free subscriptions support
  * Orientation handling improvement

* **3.2.3** (25/10/2012)
  * Added more complete user-agent to work with JS that do user-agent detection for features
  * Fix: HTML5 Video playback now uses the Audio session
  * Fix: long touch doesn't trigger the index bar anymore

* **3.2.2** (10/10/2012)
  * iOS 6 and iPhone 5 display support
  * Improved modal web view offline handling
  * Fixed orientation bug and javascript property
  * Fixed modal web view crash when interrupted and other minor fixes
  * For developers: now Baker view is a separate class
  * User agent and status bar tweaks (thanks to @jcampbell05)

* **3.2.1** (20/08/2012)
  * Internal release

* **3.2** (20/03/2012)
  * iOS 5.1 and Retina display support
  * External links now open in internal browser, see referrer=Baker (thanks to @steiny2k)
  * Custom events fired on window blur and focus
  * Book.json parameters to disable tap and swipe: -baker-page-turn-tap/swipe
  * Index bar dynamically sized from index.html size. Use viewport meta property to configure
  * Change: referrer=Baker variable now not passed to destination website
  * Fix: "white flash" workaround found
  * Fix: solved issue with pre-compiled screenshots and books with more than 50 pages
  * Fix: rare bug of content loaded into index view instead of page

* **3.1** (20/12/2011)
  * Newsstand basic support
  * iOS5/iCloud data storage guidelines support
  * Pre-build screenshots in screenshot mode using -baker-page-screenshots in book.json
  * Retina display support in screenshot mode (thanks to @zenz)
  * Manga support: start from the last page, or any arbitrary page using -baker-start-at-page in book.json
  * Email protocol support
  * Change JSON library to JSONKit (thanks to @zenz)
  * Fix: block idle when downloading
  * Fix: spinner color and iOS4.x support
  * Change: -baker-background-image-* properties are now relative to ./book/ folder, see Issue #247

* **3.0.2** (29/10/2011)
  * Fix: iOS 4 support for the spinner feature available only in iOS 5

* **3.0** (18/10/2011)
  * Two rendering modes to improve performances: screenshots (thanks to @pugpig) and three-cards
  * index.html view on double-tap to manage navigation and menu
  * Full Hpub 1.0 support
  * Improved rendering speed and responsiveness
  * Improved handling of internal and external links
  * Memory optimization
  * iOS 5 and Xcode 4.2 compatibility
  * Minimum supported version: iOS 4.0
  * Minor fixes and improvements
  * Thanks to @francesctovar @therabidbanana @eaglejohn @ffranke for the great support

* **2.0** (28/04/2011)
  * Multi-orientation books support: portrait, landscape, both (thanks to @svdgraaf)
  * iPhone support
  * Xcode 4 compatibility
  * Added support to open a specific page of a downloaded book
  * Added support to remove vertical bounce (for non-scrolling books)
  * Added support to enable automatic media playback
  * Changed the gesture to open the status bar to the more reliable doubletap
  * Fix: page anchors now handled in internal links
  * Fix: orientationchange event now fires
  * Minimum supported version: iOS 3.2
  * Minor fixes

* **1.1** (19/01/2011)
  * Added book:// protocol to allow downloadable HPub books
  * Support for zipped HPub books (to allow downloading)
  * Link support (internal/external)
  * Multitap page navigation
  * Alphabetical ordering (WARNING: breaks previous books, check before upgrading)
  * Statusbar on tap
  * Full screen swipes
  * Fix: now the previous page doesn't flash anymore when you change page
  * Minor fixes

* **1.0** (03/11/2010)
  * First release


LICENSE
-------

  _Copyright (C) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi_
  _Licensed under **BSD Opensource License** (free for personal and commercial use)_


> _Elementary, my dear Watson._
