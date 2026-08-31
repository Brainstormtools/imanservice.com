import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import { defineConfig, type Plugin } from 'vite';
import contactHandler from './api/contact.ts';
import proposalHandler from './api/proposal.ts';

function serverlessApiPlugin(): Plugin {
  return {
    name: 'serverless-api-dev-handler',
    configureServer(server) {
      server.middlewares.use(async (req, res, next) => {
        const url = req.url?.split('?')[0];

        if (url === '/api/contact') {
          // Adapt to Vercel handler interface for dev server
          const vercelRes: any = res;
          vercelRes.status = (code: number) => {
            res.statusCode = code;
            return vercelRes;
          };
          vercelRes.json = (data: any) => {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(data));
            return vercelRes;
          };
          vercelRes.send = (data: any) => {
            res.end(data);
            return vercelRes;
          };
          return contactHandler(req as any, vercelRes);
        }

        if (url === '/api/proposal') {
          const vercelRes: any = res;
          vercelRes.status = (code: number) => {
            res.statusCode = code;
            return vercelRes;
          };
          vercelRes.json = (data: any) => {
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify(data));
            return vercelRes;
          };
          vercelRes.send = (data: any) => {
            res.end(data);
            return vercelRes;
          };
          return proposalHandler(req as any, vercelRes);
        }

        next();
      });
    }
  };
}

export default defineConfig(() => {
  return {
    plugins: [react(), tailwindcss(), serverlessApiPlugin()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    server: {
      port: 3000,
      host: '0.0.0.0',
      hmr: process.env.DISABLE_HMR !== 'true',
      watch: process.env.DISABLE_HMR === 'true' ? null : {},
    },
  };
});
