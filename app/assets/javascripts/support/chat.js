function Support() {}
Support.prototype = {
  log: function(msg) {
    console.log("[Support] " + msg);
  },

  fetchThread: function(callback) {
    $.ajax('/threads/create', {context: this, headers: {'X-CSRF-Token': Rails.csrfToken()}})
      .done(function(response) {
        this.log("Thread retrieved: " + response);
        callback(response);
      }).fail(function() {
        this.log("Failed to retrieve thread!");
        callback(null);
      });
  },

  openThread: function(callback) {
    this.fetchThread(function(id) {
      var thread = new Thread(id, this.log);
      App.cable.subscriptions.create({ channel: "SupportChannel", thread: id }, {
        received: thread.onMessage.bind(thread)
      });
      thread.update(function() {
        callback(thread);
      });
    }.bind(this));
  }
}

function Thread(id, logger) {
  this.id = id;
  this.logger = logger;
  this.onMessageCallback = function(msg){this.log(msg.sender.name + ": " + msg.message)};
}
Thread.prototype = {
  log: function(msg) {
    this.logger('[' + this.id + '] ' + msg);
  },

  fetchMessages: function(callback) {
    $.ajax('/threads/' + this.id + '/messages', {context: this, headers: {'X-CSRF-Token': Rails.csrfToken()}})
      .done(function(messages) {
        this.log(messages.length + " messages retrieved");
        callback(messages);
      }).fail(function() {
        this.log("Failed to retrieve messages!");
        callback(null);
      });
  },

  sendMessage: function(text) {
    $.ajax('/threads/' + this.id + '/messages', {method: "POST", data: {text: text}, context: this, headers: {'X-CSRF-Token': Rails.csrfToken()}});
  },

  update: function(callback) {
    this.fetchMessages(function(messages) {
      if (typeof callback == 'function') callback();
      messages.forEach(function(msg){this.onMessage(msg)}.bind(this));
    }.bind(this));
  },

  onMessage: function(arg) {
    if (typeof arg == 'function') {
      this.onMessageCallback = arg;
    } else {
      this.onMessageCallback(arg);
    }
  }
}

window.Support = new Support();
