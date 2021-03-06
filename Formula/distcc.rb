class PythonWithoutPPCRequirement < Requirement
  fatal true
  satisfy(build_env: false) { !archs_for_command("python").ppc? }

  def message
    "This software will not compile if your default Python is built with PPC support."
  end
end

class Distcc < Formula
  desc "Distributed compiler client and server"
  homepage "https://code.google.com/p/distcc/"
  url "https://distcc.googlecode.com/files/distcc-3.2rc1.tar.gz"
  sha256 "8cf474b9e20f5f3608888c6bff1b5f804a9dfc69ae9704e3d5bdc92f0487760a"

  bottle do
    sha256 "67cace8962a3046e66c71726e0800b93635e2b51d5ae95d1a4465ec6c93e3a93" => :el_capitan
    sha256 "e2fb841415d554487d5cd7a9410862c08b99bde86d59e78d007b1eaf73173bdf" => :yosemite
    sha256 "bf0e1b9468861414802356814229c8c1256abf22fb00bc2819644f4f6e336485" => :mavericks
  end

  depends_on PythonWithoutPPCRequirement

  def install
    # Make sure python stuff is put into the Cellar.
    # --root triggers a bug and installs into HOMEBREW_PREFIX/lib/python2.7/site-packages instead of the Cellar.
    inreplace "Makefile.in", '--root="$$DESTDIR"', ""

    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
    plist_path.write startup_plist
    plist_path.chmod 0644
  end

  def startup_plist; <<-EOPLIST.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>ProgramArguments</key>
        <array>
            <string>#{HOMEBREW_PREFIX}/bin/distccd</string>
            <string>--daemon</string>
            <string>--no-detach</string>
            <string>--allow=192.168.0.1/24</string>
        </array>
        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}</string>
      </dict>
    </plist>
    EOPLIST
  end

  def caveats; <<-EOS.undent
    Use 'brew services start distcc' to start distccd automatically on login.
    By default, it will allow access to all clients on 192.168.0.1/24.
    EOS
  end

  test do
    system "#{bin}/distcc", "--version"
  end
end
