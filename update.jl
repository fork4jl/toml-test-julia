using JSON
using Downloads
using Tar
using p7zip_jll

const url = "https://github.com/BurntSushi/toml-test/archive/refs/tags/v1.5.0.tar.gz"
const tarname = basename(url)
const version = lstrip(split(tarname, ".tar.gz")[1], 'v')

# From Pkg
function exe7z()
    # If the JLL is available, use the wrapper function defined in there
    if p7zip_jll.is_available()
        return p7zip_jll.p7zip()
    end
    return Cmd([find7z()])
end

function find7z()
    name = "7z"
    Sys.iswindows() && (name = "$name.exe")
    for dir in (joinpath("..", "libexec"), ".")
        path = normpath(Sys.BINDIR::String, dir, name)
        isfile(path) && return path
    end
    path = Sys.which(name)
    path !== nothing && return path
    error("7z binary not found")
end

function convert_json_files(testfiles::AbstractString)
    for (root, dirs, files) in walkdir(testfiles)
        for f in files
            file = joinpath(root, f)
            endswith(file, ".json") || continue
            d_json = open(JSON.parse, file)
            d_jl = repr(d_json)
            write(splitext(file)[1] * ".jl", d_jl)
            rm(file)
        end
    end
end


function update()
    tmp = mktempdir()
    path = joinpath(tmp, basename(url))
    Downloads.download(url, path)
    Tar.extract(`$(exe7z()) x $path -so`, joinpath(tmp, "testfiles"))
    test_dir = joinpath(tmp, "testfiles", "toml-test-$version", "tests")
    convert_json_files(test_dir)
    for (root, dirs, files) in walkdir(".")
        for file in files
            path = joinpath(root, file)
            if endswith(path, ".json")
                rm(path)
            end
        end
    end
    mv(test_dir, joinpath(@__DIR__, "testfiles"), force=true)
end

update()
