###
Module dependencies.
###
os = require("os")
cluster = require("cluster")

###
Cluster setup.
###

# Setup the cluster to use app
cluster.setupMaster exec: "app.js"

# Listen for dying workers
cluster.on "exit", (worker) ->
  console.log "Worker " + worker.id + " died"

  # Replace the dead worker
  cluster.fork()
  return


# Fork a worker for each available CPU
i = 0

while i < os.cpus().length
  cluster.fork()
  i++
