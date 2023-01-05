variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
  default     = "b1gvkuni87is2cev03ro"
}

variable "folder_id" {
  type        = string
  description = "Yandex Cloud folder"
  default     = "b1gp8v55632cik3ud0ro"
}

variable "IAM_token" {
  type        = string
  description = "Yandex IAM token"
  sensitive   = true
}

variable "image_id" {
  type        = string
  description = "Image of the VM"
  default     = "fd81u2vhv3mc49l1ccbb"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet"
  default     = "e9bhkjni7fseb3tqtjfv"
}

variable "zone" {
  type        = string
  description = "Availability zone"
  default     = "ru-central1-a"
}

variable "vps_platform_id" {
  type        = string
  description = "Hardware platform identifier of the VM"
  default     = "standard-v2"
}

variable "vps_count" {
  type        = string
  description = "Count of VPS"
  default     = "1"
}

variable "vps_ram" {
  type        = string
  description = "Amout of RAM"
  default     = "1"
}

variable "vps_cores" {
  type        = string
  description = "Amout of CPU cores"
  default     = "1"
}

variable "vps_core_fraction" {
  type        = string
  description = "Amout of CPU core fraction"
  default     = "20"
}

variable "vps_nat" {
  type        = bool
  description = "External IP NAT"
  default     = true
}

variable "vps_boot_disk_size" {
  type        = string
  description = "Disk size on master node"
  default     = "25"
}

variable "vps_serial-port-enable" {
  type        = string
  description = "Serial port enable or not"
  default     = "1"
}
