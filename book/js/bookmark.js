/*
 * Baker Ebook Framework - Bookmarks functionality using HTML5 localStorage
 *
 * This is just a quick & dirty example, it should work but could be improved...
 *
 * Author: Cedric Kastner <cedric@nur-text.de>
 */
var Bookmark = {

  db: null,
  list: [],
  exists: null,
  filename: null,
  title: null,
  listel: null,
  btnel: null,

  init: function(listid, btnid) {
    this.listel = document.getElementById(listid);
    this.btnel  = document.getElementById(btnid);

    this.db = openDatabase('bookmarks', '1.0', 'Bookmarks for Baker', 1024*1024);

    this.db.transaction(function(tx) {
      tx.executeSql('CREATE TABLE IF NOT EXISTS bookmarks (filename TEXT NOT NULL PRIMARY KEY UNIQUE, title TEXT NOT NULL);');
      
      tx.executeSql('SELECT filename, title FROM bookmarks;', [], function (tx, res) {
        var len = res.rows.length, i, j;
        
        for (i = 0; i < len; i++) {
          Bookmark.list.push({filename: res.rows.item(i).filename, title: res.rows.item(i).title});
        }

        if (Bookmark.list && Bookmark.listel) {
          ol = document.createElement("ol");
          
          for(j = 0; j < Bookmark.list.length; j++) {
            a = document.createElement("a");
            a.appendChild(document.createTextNode(Bookmark.list[j].title));
            a.setAttribute("href", Bookmark.list[j].filename);

            li = document.createElement("li");
            li.appendChild(a);

            ol.appendChild(li);
          }

          Bookmark.listel.appendChild(ol);
        }
      });

      tx.executeSql('SELECT filename FROM bookmarks WHERE filename = ?;', [Bookmark.filename], function(tx, res) {
        Bookmark.exists = (res.rows.length) ? true : false;
        
        if (Bookmark.btnel) {
          if (Bookmark.exists) Bookmark.btnel.setAttribute("class", "isSet");

          Bookmark.btnel.addEventListener("click", function() {
            if (Bookmark.exists) {
              Bookmark.btnel.removeAttribute("class");
              Bookmark.remove();
            } else {
              Bookmark.btnel.setAttribute("class", "isSet");
              Bookmark.add();
            }
          });
        }
      });
    });

    this.filename = location.href.replace(/^.*[\\\/]/, '');
    this.title    = document.title;
  },

  isSet: function() {
    return this.exists;
  },

  getAll: function() {
    return this.list;
  },

  add: function(filename) {
    filename = (filename) ? filename : this.filename;

    if (!this.exists) {
      this.db.transaction(function(tx) {
        tx.executeSql('INSERT INTO bookmarks VALUES (?, ?)', [filename, Bookmark.title], function(tx, res) {
          if (res.rowsAffected) {
            if (filename == Bookmark.filename) Bookmark.exists = true;
          }
        });
      });
    }
  },

  remove: function(filename) {
    filename = (filename) ? filename : this.filename;

    if (this.exists) {
      this.db.transaction(function(tx) {
        tx.executeSql('DELETE FROM bookmarks WHERE filename = ?', [filename], function(tx, res) {
          if (res.rowsAffected) {
            if (filename == Bookmark.filename) Bookmark.exists = false;
          }
        });
      });
    }
  }

};