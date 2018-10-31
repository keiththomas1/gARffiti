'use strict';
module.exports = function(app) {
	let locations = require('../controllers/locationController');
	//let pictures = require('../controllers/pictureController');

	// POST pictures
	//app.route('/locations')
	//	.post(locations.createLocation);

	// GET pictures
	//app.route('/listLocations')
	//	.get(locations.listLocations);
	/*app.route('/listPictures/:count')
		.get(pictures.listPictures);
	app.route('/listPictures/:count/:timestamp')
		.get(pictures.listPicturesByTime);
	app.route('/listFeedbackNeededPictures/:count')
		.get(pictures.listFeedbackNeededPictures);*/

	// Picture modifications
	app.route('/locations')
		.put(locations.updateLocation)
		.post(locations.createLocation)
		.get(locations.getLocation);
	/*app.route('/pictures/:pictureID')
		.put(pictures.updatePicture)
		.get(pictures.readPicture);
	app.route('/liked/:pictureID/:userID')
		.put(pictures.incrementLikes);
	app.route('/disliked/:pictureID/:userID')
		.put(pictures.incrementDislikes);*/
};
