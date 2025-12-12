import { defineConfig, globalIgnores } from 'eslint/config';
import nextVitals from 'eslint-config-next/core-web-vitals';
import nextTs from 'eslint-config-next/typescript';
import prettierConfig from 'eslint-config-prettier';
import prettierPlugin from 'eslint-plugin-prettier';

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  prettierConfig, // 与 Prettier 兼容
  {
    plugins: {
      prettier: prettierPlugin,
    },
    rules: {
      'prettier/prettier': 'error', // 启用 Prettier 规则
      '@typescript-eslint/no-unused-vars': 'warn', // 未使用变量警告
      'react/no-array-index-key': 'warn', // 使用数组索引作为 key 警告
      'no-console': ['warn', { allow: ['warn', 'error'] }], // 允许 console.warn 和 console.error
    },
  },
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    '.next/**',
    'out/**',
    'build/**',
    'next-env.d.ts',
  ]),
]);

export default eslintConfig;
