import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vitest/config';
import { nodePolyfills } from 'vite-plugin-node-polyfills'
import devtoolsJson from 'vite-plugin-devtools-json';

export default defineConfig({
	plugins: [sveltekit(), nodePolyfills(),devtoolsJson()],
	test: {
		include: ['src/**/*.{test,spec}.{js,ts}']
	},
	server: {
                allowedHosts: ['localhost', '127.0.0.1', '0.0.0.0', '.aristomate.gr', 'aristomate.auth.gr']
        }
});
