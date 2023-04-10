
module.exports = {
	mode: 'development',
	// Example setup for your project:
	// The entry module that requires or imports the rest of your project.
	// Must start with `./`!
	entry: './src/index.js',
	// Place output files in `./dist/my-app.js`
	output: {
		path: __dirname + '/wwwroot/dist',
		filename: 'chat-client.js',
	},
};