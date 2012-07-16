/*
 * Baker Ebook Framework - Basic Book
 * last update: 2011-07-18
 * 
 * Copyright (C) 2011 by Davide S. Casali <folletto AT gmail DOT com>
 * 
 *
 * Usage:
 *   Define the CSS for 'blood-drop'.
 *   Init with the position of the dripping point:
 *
 *     Blood.init(x, y, timeInterval);
 *
 */

var Blood = {
  
  sprite: null,
  init: { x: 0, y: 0 },
  loopCreate: null,
  loop: null,
  documentHeight: 0,
  accelerometer: { x: 0, y: 0, oldX: null, oldY: null },
  accelerometerSensitivity: 100,
  
  init: function(x, y, time) {
    this.sprite = document.createElement('div');
    this.sprite.setAttribute('class', 'blood-drop');
    this.sprite.style.position = "absolute";
    
    // Position
    this.init.x = x;
    this.init.y = y;
    this.positionToCSS(this.init.x, this.init.y, this.sprite);
    
    // Wait and attach
    var self = this;
    document.addEventListener("DOMContentLoaded", function() {
      self.documentHeight = document.body.offsetHeight;
      document.body.appendChild(self.sprite);
    }, false);
    window.addEventListener("devicemotion", function(e) {
      // Process event.acceleration, event.accelerationIncludingGravity,
      // event.rotationRate and event.interval
      self.accelerometer.x = parseInt(e.accelerationIncludingGravity.x * self.accelerometerSensitivity);
      self.accelerometer.y = parseInt(-e.accelerationIncludingGravity.y * self.accelerometerSensitivity);
      if (oldX != null && self.accelerometer.x != self.accelerometer.oldX && self.accelerometer.y != self.accelerometer.oldY) {
        self.drop();
      }
      self.accelerometer.oldX = self.accelerometer.x;
      self.accelerometer.oldY = self.accelerometer.y;
    }, false);
    
    if (this.loop) clearTimeout(this.loop); // wrong position
    this.loopCreate = setInterval("Blood.drop()", time);
  },
  
  positionToCSS: function(x, y, sprite) {
    if (x >= 0) sprite.style.top = x + "px";
    else sprite.style.bottom = -x + "px";
    if (y >= 0) sprite.style.left = y + "px";
    else sprite.style.right = -y + "px";
  },
  
  drop: function() {
    if ((this.sprite.offsetTop + this.sprite.offsetHeight) < this.documentHeight) {
      this.sprite.style.top = (parseInt(this.sprite.style.top) * 1.038) + "px";
      this.loop = setTimeout("Blood.drop()", 1);
    } else {
      this.positionToCSS(this.init.x, this.init.y, this.sprite);
    }
  }
}