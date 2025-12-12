import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';

export const metadata: Metadata = {
  title: '压测平台 - 用户前台',
  description: '压力测试平台用户前台',
};

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang='zh-CN'>
      <body className={`${geistSans.variable} ${geistMono.variable} antialiased`}>
        {/* 主要内容区域 */}
        <div style={{ padding: '24px' }}>{children}</div>

        {/* 页脚 */}
        <footer style={{ textAlign: 'center', padding: '20px', borderTop: '1px solid #f0f0f0' }}>
          压力测试平台 ©2025 Created by FengLong Team
        </footer>
      </body>
    </html>
  );
}
