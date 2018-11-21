'use strict';

let mongoose = require('mongoose');
let Location = mongoose.model('Locations');

// GET
exports.getLocation = function(request, response) {
  Location.find(
    {latitude: request.params.latitude, longitude: request.params.longitude},
    function(error, location) {
    if (error) {
  		console.error("getLocation error: ", error);
  		response.send(error);
      return;
	  }

  	console.log("getLocation request. response:", location);
    console.log("latitude: ", request.params.latitude);
    console.log("longitude: ", request.params.longitude);

    response.json(location);
  });
}

// POST
exports.createLocation = function(request, response) {
  let newLocation = new Location(request.body);
  newLocation.save(function(error, location) {
    if (error) {
		console.error("createLocation error: ", error);
		response.send(error);
	}
	console.log("createLocation request. response:", location);
    response.json(location);
  });
};

// UPDATE
exports.updateLocation = function(request, response) {
  Location.findOneAndUpdate(
	{_id: request.params.pictureID},
	request.body,
	{new: true},
	function(error, picture) {
		if (error) {
			console.error("updateLocation error: ", error);
			response.send(error);
		}
		console.log("updateLocation request. response:", picture);
		response.json(picture);
	}
  );
};
