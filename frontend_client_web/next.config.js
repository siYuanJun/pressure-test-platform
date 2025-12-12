/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // 确保Ant Design组件能正确进行服务器端渲染
  compiler: {
    emotion: true,
    // SWC minification is enabled by default in Next.js 16
  },
  // 配置图像加载
  images: {
    domains: [],
  },
};

module.exports = nextConfig;
