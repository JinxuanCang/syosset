// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `rails generate channel` command.
//
//= require action_cable
//= require_self

$(document).ready(function() {
  this.App || (this.App = {});

  App.cable = ActionCable.createConsumer($('body').data('action-cable-url'));
}.bind(this));