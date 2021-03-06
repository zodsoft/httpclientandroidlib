#!/bin/bash

HTTPCOREANDROIDLIB_VER=4.3.3
HTTPCLIENTANDROIDLIB_VER=4.3.5
ANDROIDSDKPATH=hello
ANDROID_API_TARGET=21

if [ ! -d "${ANDROIDSDKPATH}" ]; then
  if [ -d "/Applications/Android Studio.app/sdk" ]; then
    printf "\nSDK path not set, defaulting to Android Studio's SDK directory in '/Applications/Android Studio.app/sdk'.\n"
    ANDROIDSDKPATH="/Applications/Android\ Studio.app/sdk"
  else
    printf "\nPlease set your SDK path in the script file!\n"
    exit
  fi
fi

printf "\n >>> Building for HTTP core ${HTTPCOREANDROIDLIB_VER}, HTTP client ${HTTPCLIENTANDROIDLIB_VER}, with Android API target ${ANDROID_API_TARGET}…\n\n"

# Checkout svn repositories of core/client/cache
svn checkout http://svn.apache.org/repos/asf/httpcomponents/httpcore/tags/${HTTPCOREANDROIDLIB_VER}/httpcore/ httpcore
svn checkout http://svn.apache.org/repos/asf/httpcomponents/httpclient/tags/${HTTPCLIENTANDROIDLIB_VER}/httpclient/ httpclient
svn checkout http://svn.apache.org/repos/asf/httpcomponents/httpclient/tags/${HTTPCLIENTANDROIDLIB_VER}/httpclient-cache/ httpclient-cache
svn checkout http://svn.apache.org/repos/asf/httpcomponents/httpclient/tags/${HTTPCLIENTANDROIDLIB_VER}/httpmime/ httpmime

# Delete all .svn directories
find . -type d -name ".svn" -exec rm -Rf {} +

# Delete ehcache and memcached from httpclient-cache
rm -Rf httpclient-cache/src/main/java/org/apache/http/impl/client/cache/ehcache
rm -Rf httpclient-cache/src/main/java/org/apache/http/impl/client/cache/memcached

PROJECTNAME=httpclientandroidlib
PACKAGENAME=ch.boye.httpclientandroidlib
ROOTDIR=`pwd`
ROOTDIR=${ROOTDIR/ /\/ }
PACKAGEDIR=${ROOTDIR}/${PROJECTNAME}/src/${PACKAGENAME//./\/}
ANDROIDPROJECTPATH=${ROOTDIR}/${PROJECTNAME}

# Create Android library project
rm -Rf ${ANDROIDPROJECTPATH}
${ANDROIDSDKPATH}/tools/android create lib-project -n ${PROJECTNAME} -t android-${ANDROID_API_TARGET} -p ${ANDROIDPROJECTPATH} -k ${PACKAGENAME}

# Create package directory
mkdir -p ${PACKAGEDIR}

# Copy all source files to new package directory
CLIENTDIR=`find . -type d | grep '/httpclient/src/main/java/org/apache/http$'`
CLIENTCACHEDIR=`find . -type d | grep '/httpclient-cache/src/main/java/org/apache/http$'`
CLIENTMIMEDIR=`find . -type d | grep '/httpmime/src/main/java/org/apache/http$'`
COREDIR=`find . -type d | grep '/httpcore/src/main/java/org/apache/http$'`
cd ${ROOTDIR}/${COREDIR}
cp -R * ${PACKAGEDIR}
cd ${ROOTDIR}/${CLIENTDIR}
cp -R * ${PACKAGEDIR}
cd ${ROOTDIR}/${CLIENTCACHEDIR}
cp -R * ${PACKAGEDIR}
cd ${ROOTDIR}/${CLIENTMIMEDIR}
cp -R * ${PACKAGEDIR}

cd ${PACKAGEDIR}

# Add androidextra.HttpClientAndroidLog to the package
mkdir androidextra
cp ${ROOTDIR}/androidextra/* androidextra
cd androidextra
find . -name "*.java" -exec sed -i "s/sedpackagename/${PACKAGENAME}/g" {} +
cd ..

# Apply Android bugfix https://android-review.googlesource.com/#/c/15755/1/src/org/apache/http/impl/conn/DefaultClientConnectionOperator.java
find . -name "DefaultClientConnectionOperator.java" -exec sed -i "s/conn.getSocket(), target.getHostName(), target.getPort()/conn.getSocket(), target.getHostName(), schm.resolvePort(target.getPort())/g" {} +

# Delete classes dependent on org.ietf
rm impl/auth/NegotiateScheme.java
rm impl/auth/NegotiateSchemeFactory.java
rm impl/auth/GGSSchemeBase.java
rm impl/auth/KerberosScheme.java
rm impl/auth/KerberosSchemeFactory.java
rm impl/auth/SPNegoScheme.java
rm impl/auth/SPNegoSchemeFactory.java

find . -name "*.java" -exec sed -i "/impl\.auth\.KerberosSchemeFactory;/c \/\* KerberosSchemeFactory removed by HttpClient for Android script. \*\/" {} +
find . -name "*.java" -exec sed -i "/impl\.auth\.SPNegoSchemeFactory;/c \/\* SPNegoSchemeFactory removed by HttpClient for Android script. \*\/" {} +
find . -name "*.java" -exec sed -i "/impl\.auth\.NegotiateSchemeFactory;/c \/\* NegotiateSchemeFactory removed by HttpClient for Android script. \*\/" {} +
find . -name "ProxyClient.java" -exec sed -i -n '1h;1!H;${;g;s/this.authSchemeRegistry.register([^)]*SPNegoSchemeFactory());/\/\* SPNegoSchemeFactory removed by HttpClient for Android script. \*\//g;p;}' {} +
find . -name "ProxyClient.java" -exec sed -i -n '1h;1!H;${;g;s/this.authSchemeRegistry.register([^)]*KerberosSchemeFactory());/\/\* KerberosSchemeFactory removed by HttpClient for Android script. \*\//g;p;}' {} +
find . -name "AbstractHttpClient.java" -exec sed -i -n '1h;1!H;${;g;s/registry.register([^)]*SPNegoSchemeFactory());/\/\* SPNegoSchemeFactory removed by HttpClient for Android script. \*\//g;p;}' {} +
find . -name "AbstractHttpClient.java" -exec sed -i -n '1h;1!H;${;g;s/registry.register([^)]*KerberosSchemeFactory());/\/\* KerberosSchemeFactory removed by HttpClient for Android script. \*\//g;p;}' {} +
find . -name "AbstractHttpClient.java" -exec sed -i -n '1h;1!H;${;g;s/registry.register([^)]*NegotiateSchemeFactory());/\/\* NegotiateSchemeFactory removed by HttpClient for Android script. \*\//g;p;}' {} +

# Replace Base64 encoding with android.util.Base64
find . -name "*.java" -exec sed -i "/commons\.codec\.binary\.Base64;/c import ${PACKAGENAME}\.androidextra.Base64;" {} +
find . -name "BasicScheme.java" -exec sed -i -n '1h;1!H;${;g;s/Base64.encodeBase64(\([^;]*\));/Base64.encode(\1, Base64.NO_WRAP);/g;p;}' {} +
find . -name "NTLMEngineImpl.java" -exec sed -i -n '1h;1!H;${;g;s/Base64.encodeBase64(resp)/Base64.encode(resp, Base64.NO_WRAP)/g;p;}' {} +
find . -name "*.java" -exec sed -i -n '1h;1!H;${;g;s/Base64.decodeBase64(\([^;]*\));/Base64.decode(\1, Base64.NO_WRAP);/g;p;}' {} +

# Replace logging stuff
find . -name "*.java" -exec sed -i "/commons\.logging\.Log;/c import ${PACKAGENAME}\.androidextra\.HttpClientAndroidLog;" {} +
find . -name "*.java" -exec sed -i "/commons\.logging\.LogFactory;/c \/\* LogFactory removed by HttpClient for Android script. \*\/" {} +
find . -name "*.java" -exec sed -i 's/Log log/HttpClientAndroidLog log/g' {} +
find . -name "*.java" -exec sed -i 's/private final HttpClientAndroidLog \(.*\) = LogFactory.getLog(\(.*\));/public HttpClientAndroidLog \1 = new HttpClientAndroidLog(\2);/g' {} +
find . -name "*.java" -exec sed -i 's/private final Log \(.*\) = LogFactory.getLog(\(.*\));/public HttpClientAndroidLog \1 = new HttpClientAndroidLog(\2);/g' {} +
find . -name "*.java" -exec sed -i 's/private final HttpClientAndroidLog log/public HttpClientAndroidLog log/g' {} +
find . -name "*.java" -exec sed -i 's/LogFactory.getLog(\(.*\))/new HttpClientAndroidLog(\1)/g' {} +

# Rename package
find . -name "*.java" -exec sed -i "s/org\.apache\.http/${PACKAGENAME}/g" {} +

cd ${ANDROIDPROJECTPATH}
sed -i "s/ACTIVITY_ENTRY_NAME/${PROJECTNAME}/g" AndroidManifest.xml
sed -i '/<\/project>/ i <path id="android\.libraries\.src"><path refid="project\.libraries\.src" \/><\/path><path id="android\.libraries\.jars"><path refid="project\.libraries\.jars" \/><\/path>' build.xml
cd ${ROOTDIR}
tar cvfz httpclientandroidlib-${HTTPCLIENTANDROIDLIB_VER}.tar.gz httpclientandroidlib
cd ${ANDROIDPROJECTPATH}
ant release
cd bin
mv classes.jar ${ROOTDIR}/${PROJECTNAME}-${HTTPCLIENTANDROIDLIB_VER}.jar
cd ${ROOTDIR}
