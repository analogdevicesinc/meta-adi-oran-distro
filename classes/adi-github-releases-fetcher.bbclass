#
# Copyright (C) 2024 Analog Devices Inc.
#
# -- adi-github-releases-fetcher --
#
# Bitbake´s fetchers are used to download source tarballs (the repo´s content) from a GitHub release.
# Apart from the repo´s content, GitHub allows uploading "binary assets" to a release.
# Those "binary assets" can be downloaded from a web browser, but Bitbake does not support them.
# This class adds a new fetcher, Adi_GitHub_Releases, to download "binary assets" from GitHub releases.
# This fetcher is used for SRC_URIs with "gh-releases" protocol.
#
# To download an asset using this bbclass on a recipe, you have to inherit adi-github-releases-fetcher,
# provide the "gh-releases" download URL and a checksum to verify the download:
#     inherit adi-github-releases-fetcher
#     SRC_URI = "gh-releases://github.com/adi-partners/adrv904x-ras-pkg/releases/download/v0.9.2/adrv904x-ras-pkg_0.9.2.zip;name=adrv904x-ras-pkg;
#     SRC_URI[adrv904x-ras-pkg.md5sum] = "970a4c45b97a7c24b7befceca1acc9f2"
#
# For private repos, access token must be provided by the GH_TOKEN variable.
# For instance:
#   local.conf:
#     GH_TOKEN = "ghp_W3ewVcky2GOrc2oQxq44grbVKXI3XO24kq5n"

python __anonymous() {

    from bb.fetch2 import FetchMethod
    from bb.fetch2 import FetchError

    #
    # class Adi_GitHub_Releases - Adi Bitbake fetcher for GitHub release assets
    #
    class Adi_GitHub_Releases(FetchMethod):

        ADI_GH_FETCHER_PROTOCOL = "gh-releases"

        #
        # Override FetchMethod supports
        #
        def supports(self, ud, d):
            return ud.type in [self.ADI_GH_FETCHER_PROTOCOL]

        #
        # Override FetchMethod recommends_checksum
        #
        def recommends_checksum(self, urldata):
            return True

        #
        # Override FetchMethod urldata_init
        #
        def urldata_init(self, ud, d):
            import urllib.parse
            ud.basename = os.path.basename(ud.path)
            ud.localfile = d.expand(urllib.parse.unquote(ud.basename))
            if not ud.localfile:
                ud.localfile = d.expand(urllib.parse.unquote(ud.host + ud.path).replace("/", "."))
            #
            # WORKAROUND checksum management
            #
            # - The FetchMethod __init__ "configure_checksum" function removes the expected checksum for
            #   fetchers whose ud.type is not in ["http", "https", "ftp", "ftps", "sftp", "s3", "az"] (see
            #   poky/bitbake/lib/bb/fetch2/__init__.py).
            # - As this "urldata_init" function is also called during FetchMethod __init__, we can add here
            #   a workaround to recover the expected checksums defined for our SRC_URIs, if any.
            #
            CHECKSUM_LIST = [ "md5", "sha256", "sha1", "sha384", "sha512" ]
            for checksum_id in CHECKSUM_LIST:
                if "name" in ud.parm:
                    checksum_name = "%s.%ssum" % (ud.parm["name"], checksum_id)
                else:
                    checksum_name = "%ssum" % checksum_id
                setattr(ud, "%s_name" % checksum_id, checksum_name)
                if checksum_name in ud.parm:
                    checksum_expected = ud.parm[checksum_name]
                elif ud.type not in ["gh-releases", "http", "https", "ftp", "ftps", "sftp", "s3", "az"]:
                    checksum_expected = None
                else:
                    checksum_expected = d.getVarFlag("SRC_URI", checksum_name)
                setattr(ud, "%s_expected" % checksum_id, checksum_expected)

        #
        # Override FetchMethod download
        #
        def download(self, ud, d):
            # Remove other fields apart from the url
            ud.url = ud.url.split(';')[0]
            # Replace our protocol by https
            ud.url = ud.url.replace(self.ADI_GH_FETCHER_PROTOCOL + '://', 'https://')
            # Fetch
            releases_url         = self._get_api_releases_url(ud.url)
            releases_info        = self._download_releases_info(releases_url)
            asset_url,asset_name = self._get_asset_url_and_name(releases_info, ud.url)
            self._download_asset(asset_url, asset_name)
            return True

        #
        # Get API releases URL from the provided URL
        #
        def _get_api_releases_url(self, url):
            import re
            if not re.match('https://github.com/[^/]+/[^/]+/releases/.*', url):
                raise FetchError("SRC_URI does not match GitHub Releases URLs: 'github.com/<owner>/<repo>/releases/...'")
            return re.sub('github.com/([^/]+)/([^/]+)/releases/.*', r'api.github.com/repos/\1/\2/releases', url)
        #
        # Download the releases information in json format and outputs to stdout
        #   [
        #     {
        #       (...)
        #       "assets": [
        #         {
        #           "url": "https://api.github.com/repos/adi-partners/adrv904x-ras-pkg/releases/assets/150165929",
        #           "name": "adrv904x-ras-pkg_0.9.1.zip",
        #           "browser_download_url": "https://github.com/adi-partners/adrv904x-ras-pkg/releases/download/v0.9.1/adrv904x-ras-pkg_0.9.1.zip",
        #           (...)
        #         },
        #         {
        #           "url": "https://api.github.com/repos/adi-partners/adrv904x-ras-pkg/releases/assets/150165930",
        #           "name": "adrv904x-ras-pkg_0.9.2.zip",
        #           "browser_download_url": "https://github.com/adi-partners/adrv904x-ras-pkg/releases/download/v0.9.2/adrv904x-ras-pkg_0.9.2.zip",
        #           (...)
        #         }
        #         (...)
        #       ]
        #       (...)
        #     }
        #     (...)
        #   ]
        #
        def _download_releases_info(self, releases_url):
            import re
            import subprocess
            token = d.getVar('GH_TOKEN')
            # Buld command
            cmd  = "wget -O-"                                           # wget and output to stdout
            cmd += " -q"                                                # Quiet, to remove wget traces
            if token:
                cmd += " --header=\"Authorization: token %s\""  % token # Use GitHub token if provided
            cmd += " %s" % releases_url                                 # Set URL
            # Run command
            ret = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if ret.returncode != 0:
                raise FetchError("Cannot access to releases url: " + releases_url)
            # Return releases info
            return ret.stdout

        #
        # Return URL and name of the asset whose "browser_download_url" matches the provided download URL
        #
        def _get_asset_url_and_name(self, releases_info, download_url):
            import json
            releases_json = json.loads(releases_info)
            asset_url = ""
            asset_name = ""
            for release in releases_json:
                for asset in release["assets"]:
                    if asset["browser_download_url"] == download_url:
                        asset_url  = asset["url"]
                        asset_name = asset["name"]
            if asset_url == "":
                raise FetchError("Cannot find asset URL for " + download_url)
            if asset_name == "":
                raise FetchError("Cannot find asset name for " + download_url)
            return asset_url,asset_name

        #
        # Download the asset from the provided URL to the "download_dir" folder and "asset_name" filename
        #
        def _download_asset(self, asset_url, asset_name):
            import subprocess
            token        = d.getVar('GH_TOKEN')
            download_dir = d.getVar('DL_DIR')
            # Buld command
            cmd = "wget"                                                # Base command
            cmd += " --header=\"Accept: application/octet-stream\""     # Allow downloading binary
            if token:
                cmd += " --header=\"Authorization: token %s\"" % token  # Use GitHub token if provided
            cmd += " -P %s -O %s" % (download_dir, asset_name)          # Set download path
            cmd += " '%s'" % asset_url                                  # Set URL
            # Run command
            ret = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            if ret.returncode != 0:
                raise FetchError("Cannot fetch from asset URL: " + asset_url)

    #
    # Let Bitbake know our Adi Github Releases fetcher
    #
    bb.fetch2.methods.append(Adi_GitHub_Releases())
}
