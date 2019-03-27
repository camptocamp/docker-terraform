FROM debian:9 as downloader

ENV \
	GOPASS_VERSION=1.8.3 \
	SUMMON_VERSION=0.6.9 \
	TERRAFORM_VERSION=0.11.13

RUN apt-get update && apt-get install -y \
	git \
	gpg \
	unzip \
	wget \
	&& rm -rf /var/lib/apt/lists/*

# Install gopass
RUN wget https://github.com/gopasspw/gopass/releases/download/v${GOPASS_VERSION}/gopass-${GOPASS_VERSION}-linux-amd64.tar.gz -qO - | tar xz gopass-${GOPASS_VERSION}-linux-amd64/gopass -O > /usr/local/bin/gopass
RUN chmod +x /usr/local/bin/gopass

# Install summon
RUN wget https://github.com/cyberark/summon/releases/download/v${SUMMON_VERSION}/summon-linux-amd64.tar.gz -qO - | tar xz summon -O > /usr/local/bin/summon
RUN chmod +x /usr/local/bin/summon

# Install terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O - | funzip > /usr/local/bin/terraform
RUN chmod +x /usr/local/bin/terraform

# Install terraform-inventory
RUN wget https://github.com/adammck/terraform-inventory/releases/download/v0.8/terraform-inventory_v0.8_linux_amd64.zip -O - | funzip > /usr/local/bin/terraform-inventory
RUN chmod +x /usr/local/bin/terraform-inventory

FROM debian:9

ENV \
	HOME=/home/terraform \
	SUMMON_PROVIDER=/usr/local/bin/summon-gopass

RUN apt-get update && apt-get install -y \
	git \
	wget \
	gpg \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=downloader /usr/local/bin/gopass /usr/local/bin/gopass
COPY --from=downloader /usr/local/bin/summon /usr/local/bin/summon
COPY --from=downloader /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=downloader /usr/local/bin/terraform-inventory /usr/local/bin/terraform-inventory

# Install ansible
RUN wget http://ppa.launchpad.net/ansible/ansible/ubuntu/pool/main/a/ansible/ansible_2.7.9-1ppa~trusty_all.deb -O ansible.deb \
	&& dpkg -i ansible.deb; apt-get install -f -y \
	&& rm ansible.deb

# Create home dir
RUN mkdir -p $HOME && chown 1001:0 -R $HOME && chmod g=u -R $HOME

# Install plugins
RUN mkdir -p $HOME/.terraform.d/plugins

# Configure plugin cache
RUN echo 'plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"' > /.terraformrc

RUN chown 1001:0 -R $HOME/.terraform.d

COPY summon-gopass /usr/local/bin/summon-gopass

USER 1001
