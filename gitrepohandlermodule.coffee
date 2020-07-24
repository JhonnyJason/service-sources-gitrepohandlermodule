gitrepohandlermodule = {name: "gitrepohandlermodule"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["gitrepohandlermodule"]?  then console.log "[gitrepohandlermodule]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
#region node_modules
fs = require("fs-extra")
git = require("simple-git/promise")
pathModule = require("path")
#endregion

############################################################
#region internalProperties
rootDir = ""
repoDirs = []

upstreamremotes = []
#endregion

############################################################
gitrepohandlermodule.initialize = () ->
    log "gitrepohandlermodule.initialize"
    c = allModules.configmodule

    rootDir = pathModule.resolve(process.cwd(), c.gitRootPath)

    for repo in c.contentRepos
        upstreamremote = 'https://' + c.user + ':' + c.pass + '@' + repo
        upstreamremotes.push(upstreamremote)

    for path in c.contentRepoPaths
        repoDir = pathModule.resolve(process.cwd(), path)
        repoDirs.push(repoDir)

    return
    
############################################################
#region internalFunctions
tryPull = ->
    log "tryPull"
    hadError = false
    for repo,index in repoDirs
        try
            result = await git(repo).pull("origin", "master")
            log JSON.stringify(result)
        catch err
            fs.removeSync(repo)
            hadError = true
    if hadError then await doInitialClone()
    return

doInitialClone = ->
    log "doInitialClone"
    for dir,index in repoDirs when !fs.existsSync(dir)
        remote = upstreamremotes[index]
        result = await git(rootDir).clone(remote)
        log JSON.stringify(result)
    return

directoriesExist = ->
    for dir in repoDirs
        if !fs.existsSync(dir) then return false
    return true

#endregion

############################################################
#region exposedFunctions
gitrepohandlermodule.pullContents = ->
        log "gitrepohandlermodule.pullContents"
        await tryPull()
        return

gitrepohandlermodule.pushContents = ->
        log "gitrepohandlermodule.pushContents"
        result = ""
        try 
            result = await git(repoDir).add(".")
            log result
            result = await git(repoDir).commit("automated commit by the service-sources-gitrepohandlermodule")
            log result
            result = await git(repoDir).push("origin", "master")
            log result
        catch error then log error
        return

gitrepohandlermodule.startupCheck = ->
    log "gitrepohandlermodule.startupCheck"
    if directoriesExist() then await tryPull()
    else await doInitialClone()
    return

#endregion

module.exports = gitrepohandlermodule