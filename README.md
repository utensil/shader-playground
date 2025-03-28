# My Playground for Developing Shaders for Ghostty Terminal

This is a dedicated space where you can experiment with and develop your shaders for the Ghostty terminal. Use the following command to start a local server with file watching enabled:

## Getting Started

1. Make sure you have [BrowserSync](https://browsersync.io/docs/installation) installed globally via npm:
   ```bash
   npm install -g browser-sync
   ```

2. Navigate to your project directory:
   ```bash
   cd /path/to/your/project
   ```

3. Run the command to start the development server:
   ```bash
   browser-sync start --server --files "./*" "shaders/*"
   ```

4. Open your browser and go to `http://localhost:3000` to see your shaders in action.

