#!/usr/bin/env node

/**
 * Script to get Redirect URI for OpenID Connect configuration
 * Usage: node scripts/get-redirect-uri.js [domain]
 * 
 * Example:
 *   node scripts/get-redirect-uri.js https://dev.example.com
 *   node scripts/get-redirect-uri.js https://myapp.azurewebsites.net
 */

const domain = process.argv[2] || 'http://localhost:5173';
const redirectUri = `${domain}/auth/callback`;

console.log('='.repeat(60));
console.log('🔐 OpenID Connect Redirect URI');
console.log('='.repeat(60));
console.log('');
console.log('📋 Redirect URI cần đăng ký với Admin:');
console.log(`   ${redirectUri}`);
console.log('');
console.log('📧 Thông tin gửi cho Admin:');
console.log('   - Client ID: mindx-onboarding');
console.log(`   - Redirect URI: ${redirectUri}`);
console.log('   - Environment: Dev/Production');
console.log('   - Application: Week 1 Full-Stack Application');
console.log('');
console.log('='.repeat(60));

