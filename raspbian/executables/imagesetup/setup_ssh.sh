#!/bin/bash
create_keys () {

    echo "Creating new ssh keys."
    sudo rm /etc/ssh/ssh_host_*
    sudo /usr/bin/ssh-keygen -t dsa -N "" -f /etc/ssh/ssh_host_dsa_key 2>&1
    sudo /usr/bin/ssh-keygen -t rsa -N "" -f /etc/ssh/ssh_host_rsa_key 2>&1
    sudo /usr/bin/ssh-keygen -t ecdsa -N "" -f /etc/ssh/ssh_host_ecdsa_key 2>&1
    sudo /usr/bin/ssh-keygen -t ed25519 -N "" -f /etc/ssh/ssh_host_ed25519_key 2>&1
    sudo cp /etc/ssh/ssh_host_rsa_key.pub /root/.ssh/authorized_keys 2>&1
    sudo cp /etc/ssh/ssh_host_rsa_key.pub /home/smarthome/.ssh/authorized_keys 2>&1
    sudo chown smarthome:users /home/smarthome/.ssh/ -R
    sudo chmod 700 /root/.ssh/ -R
    sudo chmod 700 /home/smarthome/.ssh/ -R
    sudo chmod 600 /home/smarthome/.ssh/authorized_keys
    sudo chmod 600 /root/.ssh/authorized_keys
    sudo cp /etc/ssh/ssh_host_rsa_key /home/smarthome/smarthomeng.private
    sudo chown smarthome:smarthome /home/smarthome/smarthomeng.private
    echo ""
    echo ""
    echo ""
    echo "Copy /home/smarthome/smarthomeng.private to your client and connect as smarthome or root!"
}

certs () {
    if [ -f /etc/ssh/ssh_host_rsa_key ]; then
        echo ""
        echo "SSH Keys were already generated on first boot. Do you want to create new ones anyhow?"
        select sshd in "Create" "Keep" "Skip"; do
            case $sshd in
                Create ) create_keys; break;;
                Keep )
                    echo "Keeping existing SSH keys";
                    sudo cp /etc/ssh/ssh_host_rsa_key /home/smarthome/smarthomeng.private;
                    sudo chown smarthome:smarthome /home/smarthome/smarthomeng.private;
                    break;;
                Skip ) echo "Skipping"; break;;
                *) echo "Skipping"; break;;
            esac
        done
    else
      create_keys;
    fi
    sudo systemctl restart ssh
    echo ""
    echo "It is recommended to disable password login AFTER successfully testing your ssh certificate connection."
    echo "Create a new ssh session using the certificate instead of the user/password. Use smarthome or root as User and NO password."
    echo ""
    echo "How do you want to configure password login?"
    select pwd in "Enable" "Disable" "Skip"; do
        case $pwd in
            Enable )
                sudo sed -i 's/PasswordAuthentication no/#PasswordAuthentication yes/g' /etc/ssh/sshd_config 2>&1;
                sudo sed -i 's/PermitEmptyPasswords no/PermitEmptyPasswords yes/g' /etc/ssh/sshd_config 2>&1;
                break;;
            Disable )
                sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config 2>&1;
                sudo sed -i 's/PermitEmptyPasswords yes/PermitEmptyPasswords no/g' /etc/ssh/sshd_config 2>&1;
                break;;
            Skip ) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
    echo "Password Login is set to $pwd."
    sudo systemctl restart sshd
}

nocerts () {
    echo ""
    echo "Enabling SSH password login. Login as smarthome or root with password smarthome."
    sudo sed -i 's/PasswordAuthentication no/#PasswordAuthentication yes/g' /etc/ssh/sshd_config 2>&1
    sudo sed -i 's/PermitEmptyPasswords no/PermitEmptyPasswords yes/g' /etc/ssh/sshd_config 2>&1
    sudo systemctl restart ssh
}

SSHD_e=$(systemctl is-enabled ssh 2>&1 | tail -n 1)&> /dev/null
echo ""
echo "SSH: Connect to your Raspi via network. Use a client like vssh, mobaXterm, putty, etc. (currently $SSHD_e)"
select sshd in "Enable" "Disable" "Skip"; do
    case $sshd in
        Enable ) sudo systemctl enable ssh; break;;
        Disable ) sudo systemctl disable ssh; break;;
        Skip ) echo "Skipping"; break;;
        *) echo "Skipping"; break;;
    esac
done
SSHD_e=$(systemctl is-enabled ssh 2>&1 | tail -n 1)&> /dev/null
if [[ $SSHD_e == "enabled" ]]; then
    echo ""
    echo "It is highly recommended to secure your SSH connection with certificates instead of passwords."
    echo "Do you want to enable certificates and set them up?"
    select certs in "Enable" "Disable" "Skip"; do
        case $certs in
            Enable ) certs; break;;
            Disable ) nocerts; break;;
            Skip ) echo "Skipping"; break;;
            *) echo "Skipping"; break;;
        esac
    done
fi
echo ""
echo "SSHD Service is $SSHD_e. Config file is /etc/ssh/sshd_config"
