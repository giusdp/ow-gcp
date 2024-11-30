const axios = require('axios');

/**
 * OpenWhisk action to send a GET request to a specified IP and return the size of the JSON response.
 *
 * @param {object} params - The parameters for the action.
 * @param {string} params.dataServerIp - The IP address to send the GET request to.
 * @returns {object} - A JSON object containing the size of the JSON response.
 */
async function main(params) {
    // Validate that the dataServerIp parameter is provided
    if (!params.dataServerIp) {
        return { error: "Missing parameter 'dataServerIp'" };
    }

    const url = `http://${params.dataServerIp}:8080`;

    return await axios.get(url)
        .then(response => {
            // Ensure the response data is JSON
            if (typeof response.data !== 'object') {
                return { error: "Response is not a JSON object" };
            }

            // Calculate the size of the JSON body
            const jsonSize = JSON.stringify(response.data).length;

            return { size: jsonSize };
        })
        .catch(error => {
            // Handle errors, such as connection issues or invalid IPs
            return { error: error.message };
        });
}

exports.main = main;