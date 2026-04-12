-------------------------------------------------------------------------------
section "Releases"
-------------------------------------------------------------------------------

release = {
    require "luax-targets" : map(function(target)
        local archive = archive(target)
        return build.tar(archive..".tar.gz") {
            base = archive:dirname(),
            name = archive:basename(),
            implicit_in = release,
        }
    end)
}
