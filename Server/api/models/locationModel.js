'use strict';
let mongoose = require('mongoose');
let Schema = mongoose.Schema;

let LocationSchema = new Schema({
	latitude: String,
	longitude: String,
	photo: String,
	worldMap: String,
	contributors: {
		type: String,
		default: "1"
	},
	createdDate: {
		type: Date,
		default: Date.now
	},
});

module.exports = mongoose.model('Locations', LocationSchema);
