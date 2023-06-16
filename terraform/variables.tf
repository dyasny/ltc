variable "cpuset" {
  type = string
  default = "0,1"
}

variable "mysecret" {
  type = string
  default = "this_is_super_secret"
}

variable "core_count" {
  type = number
  default = 2
}

variable "memory" {
  type = string
  default = "256"
}
