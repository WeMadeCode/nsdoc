import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";

// https://vite.dev/config/
export default defineConfig({
  base: "./",
  build: {
    outDir: "dist", // 输出目录
    assetsDir: "assets", // 资源目录
  },
  plugins: [react()],
});
