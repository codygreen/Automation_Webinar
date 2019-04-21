#!groovy
import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.getInstance()

println "--> creating local user 'admin'"
// Create user with custom pass
def user = instance.getSecurityRealm().createAccount('admin', 'someAdminPass')
user.save()

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

if (!instance.installState.isSetupComplete()) {
  println '--> Neutering SetupWizard'
  InstallState.INITIAL_SETUP_COMPLETED.initializeState()
}

git = pm.getPlugin("git")

def deployPlugin(plugin) {
  if (! plugin.isEnabled() ) {
    plugin.enable()
  }
  plugin.getDependencies().each { 
    deployPlugin(pm.getPlugin(it.shortName)) 
  }
}

deployPlugin(git)

instance.save()