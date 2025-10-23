terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.40.0"
    }
  }
}

provider "aws" {
  region = var.region
}


resource "aws_instance" "Webserver01" {
  ami                    = data.aws_ami.amznl2.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.acceskey.key_name
  subnet_id              = aws_subnet.Subnet_Web01.id
  vpc_security_group_ids = [aws_security_group.WebSG.id, aws_security_group.SSH-Acces.id]

  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
yum update -y
amazon-linux-extras enable nginx1
amazon-linux-extras enable php8.0
yum install -y nginx php-cli php-mysqlnd php-fpm

systemctl enable nginx
systemctl enable php-fpm
systemctl start nginx
systemctl start php-fpm

echo "Hello from Webserver01" > /usr/share/nginx/html/index.html


cat > /usr/share/nginx/html/dbtest.php <<EOL
<?php
\$conn = new mysqli('${aws_db_instance.database.address}', 'admin', 'Password', 'Webappdb');
if (\$conn->connect_error) {
    die('Connection failed: ' . \$conn->connect_error);
}
echo 'Connected successfully to RDS!';
?>
EOL

cat > /etc/nginx/conf.d/php.conf <<'EOL'
server {
    listen       80;
    server_name  _;

    root   /usr/share/nginx/html;
    index  index.php index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include        fastcgi_params;
        fastcgi_pass   unix:/var/run/php-fpm/www.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
EOL

systemctl restart php-fpm
systemctl restart nginx
EOF

  tags = {
    Name = "Web01"
  }
}

