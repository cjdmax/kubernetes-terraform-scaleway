provider "scaleway" {
  organization = "${var.organization_key}"
  token = "${var.secret_key}"
  region = "${var.region}"
}
# todo private nodes

data "scaleway_image" "baseimage" {
  architecture = "${var.scaleway_image_arch}"
  name         = "${var.scaleway_image_name}"
}

data "scaleway_bootscript" "docker" {
  architecture = "${var.scaleway_image_arch}"
  name         = "${var.scaleway_bootscript}"
}

resource "scaleway_server" "kubernetes_master" {
  name = "${format("${var.kubernetes_cluster_name}-master-%02d", count.index)}"
  image = "${data.scaleway_image.baseimage.id}"
  bootscript = "${data.scaleway_bootscript.docker.id}"
  dynamic_ip_required = "${var.dynamic_ip}"
  type = "${var.scaleway_master_type}"

  connection {
    user = "${var.user}"
  }

  provisioner "local-exec" {
    command = "rm -rf ./scw-install.sh ./scw-install-master.sh"
  }
  provisioner "local-exec" {
    command = "echo ${format("MASTER_%02d", count.index)}=\"${self.public_ip}\" >> ips.txt"
  }

  provisioner "local-exec" {
    command = "echo CLUSTER_NAME=\"${var.kubernetes_cluster_name}\" >> ips.txt"
  }
  provisioner "local-exec" {
    command = "./make-files.sh"
  }

  provisioner "local-exec" {
    command = "while [ ! -f ./scw-install.sh ]; do sleep 1; done"
  }

  provisioner "file" {
    source = "./scw-install.sh"
    destination = "/tmp/scw-install.sh"
  }

  provisioner "remote-exec" {
    inline = "KUBERNETES_TOKEN=\"${var.kubernetes_token}\" bash /tmp/scw-install.sh master"
  }

  provisioner "local-exec" {
    command = "ssh-keygen -f \"$HOME/.ssh/known_hosts\" -R ${self.public_ip}"
  }

  provisioner "local-exec" {
    command = "ssh-keyscan -H ${self.id}.pub.cloud.scaleway.com,${self.public_ip} >> \"$HOME/.ssh/known_hosts\""
  }

  tags = ["${var.kubernetes_cluster_name}", "${var.kubernetes_cluster_name}-master"]

}

resource "scaleway_server" "kubernetes_slave" {
  name = "${format("${var.kubernetes_cluster_name}-slave-%02d", count.index)}"
  depends_on = ["scaleway_server.kubernetes_master"]
  image = "${data.scaleway_image.baseimage.id}"
  dynamic_ip_required = "${var.dynamic_ip}"
  type = "${var.scaleway_slave_type}"
  count = "${var.kubernetes_slave_count}"
  connection {
    user = "${var.user}"
  }
  provisioner "local-exec" {
    command = "while [ ! -f ./scw-install.sh ]; do sleep 1; done"
  }
  provisioner "file" {
    source = "scw-install.sh"
    destination = "/tmp/scw-install.sh"
  }
  provisioner "remote-exec" {
    inline = "KUBERNETES_TOKEN=\"${var.kubernetes_token}\" bash /tmp/scw-install.sh slave"
  }
  
  provisioner "local-exec" {
    command = "ssh-keygen -f \"$HOME/.ssh/known_hosts\" -R ${self.public_ip}"
  }
  provisioner "local-exec" {
    command = "ssh-keyscan -H ${self.id}.pub.cloud.scaleway.com,${self.public_ip} >> \"$HOME/.ssh/known_hosts\""
  }
  
  tags = ["${var.kubernetes_cluster_name}", "${var.kubernetes_cluster_name}-slave"]
}

resource "null_resource" "ansible_provision" {
  depends_on = [ "scaleway_server.kubernetes_master", "scaleway_server.kubernetes_slave" ]

  triggers { 
    cluster_instance_ids = "${join(",", scaleway_server.kubernetes_master.*.id, scaleway_server.kubernetes_slave.*.id)}"
  }

  provisioner "local-exec" {
    command = "echo \"[masters]\n${join("\n",formatlist("%s ansible_ssh_user=root ansible_ssh_host=%s", scaleway_server.kubernetes_master.*.name, scaleway_server.kubernetes_master.*.public_ip))}\" > ansible/hosts"
  }
  provisioner "local-exec" {
    command = "echo \"[slaves]\n${join("\n",formatlist("%s ansible_ssh_user=root ansible_ssh_host=%s", scaleway_server.kubernetes_slave.*.name, scaleway_server.kubernetes_slave.*.public_ip))}\" >> ansible/hosts"
  }
  provisioner "local-exec" {
    command = "echo \"\n[all:children]\nmasters\nslaves\" >> ansible/hosts"
  }

}

