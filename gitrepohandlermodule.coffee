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
repoDir = ""

upstreamremote = ""
#endregion

############################################################
gitrepohandlermodule.initialize = () ->
    log "gitrepohandlermodule.initialize"
    c = allModules.configmodule
    upstreamremote = 'https://' + c.user + ':' + c.pass + '@' + c.contentRepo

    rootDir = pathModule.resolve(process.cwd(), c.gitRootPath)
    repoDir = pathModule.resolve(process.cwd(), c.contentRepoPath)
    return
    
############################################################
#region internalFunctions
tryPull = ->
    log "tryPull"
    try
        result = await git(repoDir).pull("origin", "master")
        log JSON.stringify(result)
    catch err
        fs.removeSync(repoDir)
        doInitialClone()
    return

doInitialClone = ->
    log "doInitialClone"
    result = await git(rootDir).clone(upstreamremote)
    log JSON.stringify(result)
    return

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
    if fs.existsSync(repoDir) then await tryPull()
    else await doInitialClone()
    return

#endregion

module.exports = gitrepohandlermodule