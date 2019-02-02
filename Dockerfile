FROM debian:9

ENV \
	HOME=/home/terraform \
	GOPASS_VERSION=1.8.3 \
	SUMMON_VERSION=0.6.9 \
	TERRAFORM_VERSION=0.11.11 \
	SUMMON_PROVIDER=/usr/local/bin/summon-gopass

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

# Create home dir
RUN mkdir -p $HOME && chown 1001:0 $HOME && chmod g=u $HOME

# Install plugins
RUN mkdir -p $HOME/.terraform.d/plugins

# Get gitlab provider
RUN wget https://github.com/mcanevet/terraform-provider-gitlab/releases/download/v1.1.0%2Bpr-68%2Bpr-72%2Bpr-83/terraform-provider-gitlab_v1.1.1 -O $HOME/.terraform.d/plugins/terraform-provider-gitlab_v1.1.1

# Set all plugins executable
RUN chmod +x $HOME/.terraform.d/plugins/*

# Configure plugin cache
RUN echo 'plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"' > /.terraformrc

COPY summon-gopass /usr/local/bin/summon-gopass

USER 1001
