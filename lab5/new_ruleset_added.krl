ruleset new_ruleset_installed {
    meta {

    }

    rule pico_ruleset_added {
        select when wrangler ruleset_installed
          where event:attr("rids") >< meta:rid
        pre {
          sensor_id = event:attr("sensor_id")
        }
        always {
          ent:sensor_id := sensor_id
        }
      }
}