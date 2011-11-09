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
   * Create you publication as one or more **HTML5 files**
   * Design your publication to fit multiple screen (if you want to target iPad: 768px for portrait, 1024px for landscape)
   * You can use **any** feature in WebKit: HTML5, CSS3, JavaScript (video, audio, fonts, jQuery, Google Maps, etc)
   * On iPad/iPhone you can constrain the height to match the page size or make it scrollable if you need longer pages
   * Consider having 1 HTML for each chapter/section/article and use the native vertical scrolling.
   * ...remember: it's a publication. If you want to build an app, check [PhoneGap](http://www.phonegap.com/). ;)

2. PACKAGE
   * The publication must be contained in a single "book/" folder
   * Each chapter/section/article (horizontally swiped on the iPad) should be a single HTML file inside the "book/" folder
   * Create a Hpub book.json file: title, author, pages, etc. (see below)
   * The assets must be contained within the "book/" folder or its subfolders
   * Check the example book from the website for an hands-on example

3. PUBLISH
   * Download the Baker Framework Xcode project from http://bakerframework.com (or GitHub).
   * Download Xcode 4.2 from the Mac App Store or from the Apple Developer website.
   * Open Baker in Xcode.
   * Add all the files of your publication from your "book/" folder to the "book/" folder inside Baker.
   * Rename the project to the name of your publication: click on the "Baker" name in the leftmost column of the project navigator.
   * Replace the icon files (ios-icon-*.png, check the [Apple Guidelines](http://developer.apple.com/library/ios/#DOCUMENTATION/UserExperience/Conceptual/MobileHIG/IconsImages/IconsImages.html) for reference).
   * Change the bundle identifier in the plist file to the one you are going to use for your app.
   * Select the Baker Scheme (Simulator or Device) from the toolbar dropdown.
   * Run and check that everything works correctly _both_ on simulator and device.
   * Create an Apple iPhone Developer account to publish on the App Store.
   * Follow the instructions on the Apple iPhone Developer website to submit your book to the app store.


BOOK.JSON
---------

This is an example of a minimal book.json file:

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

For all the details and the advanced options, check the [Hpub specification on the wiki](https://github.com/Simbul/baker/wiki/hpub-specification).


CREATE A BOOK FOR BOTH IPAD AND IPHONE
--------------------------------------

With Baker Framework you can create books and magazines for the iPhone too.

To compile your application for iPhone follow these steps:

* Open the Baker Framework Xcode project with Xcode.
* Click on the "Baker" project in the leftmost column of the project navigator.
* On the column just left, click under Projects on "Baker"
* In the "Build Settings" tab locate the section Deployment for the configuration you would like to use for compiling.
* Under the Deployment section change the Target Device Family entry to match the devices you would like to target (only iPhone, only iPad or iPhone/iPad).
* Compile and test the application.



DOWNLOADABLE BOOKS
------------------

From inside an existing book you make with Baker you can download other books, in the HPub format.

A book in the HPub format is like the default book that's inside Baker:

* All the HTML files must be at root level (not in a subfolder, otherwise you'll get an empty book).
* Each chapter/section/article (horizontally swiped on the iPad) should be a single HTML file inside the "book/" folder
* Create a Hpub book.json file: title, author, pages, etc. (see below)
* The assets must be contained within the "book/" folder or its subfolders

When it's ready:

1. Zip all the files (not the folder, remember, its content).
2. Change the extension of the file from ".zip" to ".hpub".
3. Upload the .hpub file on a server.
4. Link to the publication on the server, using the [Hpub book protocol](https://github.com/Simbul/baker/wiki/Book-protocol): `book://example.org/path/bookname`  
   (with or without extension, Baker will add ".hpub" by itself).



BUGS AND FEEDBACK
-----------------

* Submit your bugs here: <http://github.com/simbul/baker/issues>
* Give us your feedback at: <info@bakerframework.com>
* Follow us on Twitter: <http://twitter.com/BakerFramework>



CHANGELOG
---------

* **MASTER** 
  * Newsstand basic support
  * Fix: doesn't idle when downloading

* **3.0.2**
  * Fix: iOS 4 support for the spinner feature available only in iOS 5

* **3.0** 
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

* **2.0**
  * Multi-orientation books support (portrait, landscape, both) - thanks to @svdgraaf
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

* **1.1**
  * Added book:// protocol to allow downloadable HPub books
  * Support for zipped HPub books (to allow downloading)
  * Link support (internal/external)
  * Multitap page navigation
  * Alphabetical ordering (WARNING: breaks previous books, check before upgrading)
  * Statusbar on tap
  * Full screen swipes
  * Fix: now the previous page doesn't flash anymore when you change page
  * Minor fixes

* **1.0**
  * First release


LICENSE
-------

  _Copyright (C) 2010-2011, Davide Casali, Marco Colombo, Alessandro Morandi_  
  _Licensed under **BSD Opensource License** (free for personal and commercial use)_


> _Elementary, my dear Watson._
