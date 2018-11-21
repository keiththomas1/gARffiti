'use strict';
module.exports = function(app) {
	let locations = require('../controllers/locationController');
	//let pictures = require('../controllers/pictureController');

	// GET pictures
	//app.route('/listLocations')
	//	.get(locations.listLocations);

	// Picture modifications
	app.route('/locations')
		.put(locations.updateLocation)
		.post(locations.createLocation);
	app.route('/locations/:latitude/:longitude')
		.get(locations.getLocation);
	/*app.route('/pictures/:pictureID')
		.put(pictures.updatePicture)
		.get(pictures.readPicture);
	app.route('/liked/:pictureID/:userID')
		.put(pictures.incrementLikes);
	app.route('/disliked/:pictureID/:userID')
		.put(pictures.incrementDislikes);*/
};
