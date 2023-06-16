resource "nomad_job" "litecoin_job" {
  hcl2 {
    enabled = true
  }

  jobspec = <<EOT
job "litecoin_job" {
  datacenters = ["dc1"]

  group "ltc_group" {
    task "ltc_task" {
      driver = "docker"

      config {
        image = "dyasny/ltc:latest"
        cpuset_cpus = "${var.cpuset}"

      }

      env {
        RPCAUTH = "{{ secret \"/path/to/${var.mysecret}\" }}"
      }

      vault {
        policies = ["my-vault-policy"]
      }

      resources {
        cores = ${var.core_count}
        memory = ${var.memory}

      }
    }
  }
}
EOT

}

