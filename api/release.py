# The only file a release changes. Bumping VERSION is a normal deploy;
# setting BROKEN simulates a bad release on purpose (said on screen):
#   "boot"   -> the API crashes while starting
#   "health" -> the API starts, but /health answers 500
VERSION = "v3"
BROKEN = None
