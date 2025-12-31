/**
 * Get the redirect URI for the current environment
 * This URI needs to be registered with the OpenID provider
 */
export function getRedirectUri(): string {
  const origin = window.location.origin
  return `${origin}/auth/callback`
}

/**
 * Display redirect URI information in console for admin registration
 */
export function logRedirectUriInfo(): void {
  const redirectUri = getRedirectUri()
  const env = import.meta.env.MODE || 'development'
  
  console.log('='.repeat(60))
  console.log('🔐 OpenID Connect Redirect URI Configuration')
  console.log('='.repeat(60))
  console.log(`Environment: ${env}`)
  console.log(`Redirect URI: ${redirectUri}`)
  console.log('')
  console.log('📋 Please provide this Redirect URI to your admin:')
  console.log(`   ${redirectUri}`)
  console.log('')
  console.log('The admin needs to add this URI to the OpenID provider:')
  console.log('   https://id-dev.mindx.edu.vn')
  console.log('='.repeat(60))
}

