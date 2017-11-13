

#----------------------fontion instaltion DNS et hostname
function DNSHostname() 
{ 
#recuperation et ecriture du hostlocal
echo "Renseignez le nom du host local"
read hostlocal  
echo "$hostlocal" > /etc/hostname
hostname $hostlocal
#test de connection avec le dns de google si ça ne marche pas passage de la carte 1 en dhcp
if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
  echo "IPv4 is up"
else
  echo >/etc/network/interfaces
  echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp">/etc/network/interfaces
    service networking restart
fi
#intallation des paquet
echo "installation des paquets"
    apt-get update
    apt-get install bind9 bind9utils bind9-doc
 
 

#recuperation des information pour le DNS la ZRI est de la forme 1.168.192.in-addr.arpa
echo "Renseignez la zone direct DNS principal"
read DNSPrincipalZRD
echo "Renseignez la zone indirect DNS principal (la ZRI est de la forme 1.168.192.in-addr.arpa)"
read DNSPrincipalZRI
echo "Renseignez le CNAME du DNS principal"
read CNAME
echo "Renseignez IP du serveur DNS"
read IPServPrincipale
echo "Renseignez mask du serveur DNS"
read DNSServPrincipale
#remise en place de la carte 1
  echo >/etc/network/interfaces
  echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address $IPServPrincipale
netmask $DNSServPrincipale
">/etc/network/interfaces
  service networking restart
#config Resolv.conf--------------
echo " 
domain $DNSPrincipalZRD
search $DNSPrincipalZRD
nameserver $IPServPrincipale
">/etc/resolv.conf

#-----------suppr de toute trace de conf direct et indirect--------------
rm /var/cache/bind/db*
cp /etc/bind/db.empty /var/cache/bind/db.$DNSPrincipalZRD
cp /etc/bind/db.empty /var/cache/bind/db.$DNSPrincipalZRI
#-----------Zone direct Principal--------------
echo "
\$TTL    86400
@       IN      SOA     $DNSPrincipalZRD. root.$DNSPrincipalZRD. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      $hostlocal.$DNSPrincipalZRD.
$hostlocal    IN      A    $IPServPrincipale
$CNAME    IN    CNAME    $hostlocal.$DNSPrincipalZRD.


">/var/cache/bind/db.$DNSPrincipalZRD
 #-----------Zone indirect Principal--------------
#recuperation du derniere octet  
OctetPServPrincipale=$(echo ${IPServPrincipale##*.}) 

echo "
\$TTL    86400
@       IN      SOA     $DNSPrincipalZRD. root.$DNSPrincipalZRD. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      $hostlocal.$DNSPrincipalZRD.
$OctetPServPrincipale       IN      PTR     $hostlocal.$DNSPrincipalZRD.">/var/cache/bind/db.$DNSPrincipalZRI
 #-----------Named conf local--------------
echo "
//ZRD
        zone \"$DNSPrincipalZRD\" IN {
                type master;
                file \"db.$DNSPrincipalZRD\";
                allow-update{none;};
                notify yes;
//                allow-transfer {166.66.0.1;};
};

//ZRI
        zone \"$DNSPrincipalZRI\" IN {
                type master;
                file \"db.$DNSPrincipalZRI\";
                allow-update {none;};
                notify yes;
//                allow-transfer {166.66.0.1;};
};
">/etc/bind/named.conf.local
service bind9 restart 
}










#----------------------fontion instaltion DHCP

#test de connection avec le dns de google si ça ne marche pas passage de la carte 1 en dhcp
function Dhcp(){
 
if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
  echo "IPv4 is up"
else
  echo >/etc/network/interfaces
  echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp">/etc/network/interfaces
    service networking restart
fi
 
echo "installation des paquets"
    apt-get update
    apt-get install isc-dhcp-server 
    apt-get install sudo

 #recuperation des info pour la config dhcp
echo "Renseignez l'ip du serveur DHCP"
read IPServDhcp
echo "Renseignez le reseau du serveur DHCP"
read IPResServDhcp
echo "Renseignez le mask du serveur DHCP"
read MaskServDhcp
echo "Renseignez l'etendue du serveur DHCP( deux ip séparé par un espace)"
read EtenduServDhcp
echo "Renseignez le domaine des futurs clients"
read DomaineClientDhcp
echo "Renseignez la passerel par default des futurs clients"
read PasserelClientDhcp



#remise en place de la carte 1
 echo >/etc/network/interfaces
  echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address $IPServDhcp
netmask $MaskServDhcp
">/etc/network/interfaces
  service networking restart

#config dhcp dans le dhcpd.conf
echo "
 ddns-update-style none;
 
option domain-name \"$DNSPrincipalZRD\";
option domain-name-servers $IPServDhcp;

default-lease-time 600;
max-lease-time 7200;
 

 
log-facility local7;

 
subnet $IPResServDhcp netmask $MaskServDhcp {
    range $EtenduServDhcp;
    option routers $PasserelClientDhcp;
    option domain-name \"$DomaineClientDhcp\"; 
}

 
">/etc/dhcp/dhcpd.conf
service isc-dhcp-server restart


}








#----------------------fontion instaltion FTP



function Ftp(){
echo "Renseignez l'ip du serveur FTP"
read IPServFtp
echo "Renseignez mask du serveur FTP"
read MaskServFtp
#test de connection avec le dns de google si ça ne marche pas passage de la carte 1 en dhcp
if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
  echo "IPv4 is up"
else
  echo >/etc/network/interfaces
  echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp">/etc/network/interfaces
    service networking restart
fi
 
echo "installation des paquets"
    apt-get update
    apt-get install sudo
    sudo apt-get install proftpd 
    

#config FTP dans le proftpd.conf--------------
  echo "
 #
# /etc/proftpd/proftpd.conf -- This is a basic ProFTPD configuration file.
# To really apply changes, reload proftpd after modifications, if
# it runs in daemon mode. It is not required in inetd/xinetd mode.
# 

# Includes DSO modules
Include /etc/proftpd/modules.conf

# Set off to disable IPv6 support which is annoying on IPv4 only boxes.
UseIPv6       on
# If set on you can experience a longer connection delay in many cases.
IdentLookups      off

ServerName      "SRVL"
ServerType      standalone
DeferWelcome      off

MultilineRFC2228    on
DefaultServer     on
ShowSymlinks      on

TimeoutNoTransfer   600
TimeoutStalled      600
TimeoutIdle     1200

DisplayLogin                    welcome.msg
DisplayChdir                .message true
ListOptions                 "-l"

DenyFilter      \*.*/

# Use this to jail all users in their homes 
 DefaultRoot      ~

# Users require a valid shell listed in /etc/shells to login.
# Use this directive to release that constrain.
# RequireValidShell   off

# Port 21 is the standard FTP port.
Port        21

# In some cases you have to specify passive ports range to by-pass
# firewall limitations. Ephemeral ports can be used for that, but
# feel free to use a more narrow range.
# PassivePorts                  49152 65534

# If your host was NATted, this option is useful in order to
# allow passive tranfers to work. You have to use your public
# address and opening the passive ports used on your firewall as well.
# MasqueradeAddress   1.2.3.4

# This is useful for masquerading address with dynamic IPs:
# refresh any configured MasqueradeAddress directives every 8 hours
<IfModule mod_dynmasq.c>
# DynMasqRefresh 28800
</IfModule>

# To prevent DoS attacks, set the maximum number of child processes
# to 30.  If you need to allow more than 30 concurrent connections
# at once, simply increase this value.  Note that this ONLY works
# in standalone mode, in inetd mode you should use an inetd server
# that allows you to limit maximum number of processes per service
# (such as xinetd)
MaxInstances      30

# Set the user and group that the server normally runs at.
User        proftpd
Group       nogroup

# Umask 022 is a good standard umask to prevent new files and dirs
# (second parm) from being group and world writable.
Umask       022  022
# Normally, we want files to be overwriteable.
AllowOverwrite      on

# Uncomment this if you are using NIS or LDAP via NSS to retrieve passwords:
# PersistentPasswd    off

# This is required to use both PAM-based authentication and local passwords
# AuthOrder     mod_auth_pam.c* mod_auth_unix.c

# Be warned: use of this directive impacts CPU average load!
# Uncomment this if you like to see progress and transfer rate with ftpwho
# in downloads. That is not needed for uploads rates.
#
# UseSendFile     off

TransferLog /var/log/proftpd/xferlog
SystemLog   /var/log/proftpd/proftpd.log

# Logging onto /var/log/lastlog is enabled but set to off by default
#UseLastlog on

# In order to keep log file dates consistent after chroot, use timezone info
# from /etc/localtime.  If this is not set, and proftpd is configured to
# chroot (e.g. DefaultRoot or <Anonymous>), it will use the non-daylight
# savings timezone regardless of whether DST is in effect.
#SetEnv TZ :/etc/localtime

<IfModule mod_quotatab.c>
QuotaEngine off
</IfModule>

<IfModule mod_ratio.c>
Ratios off
</IfModule>


# Delay engine reduces impact of the so-called Timing Attack described in
# http://www.securityfocus.com/bid/11430/discuss
# It is on by default. 
<IfModule mod_delay.c>
DelayEngine on
</IfModule>

<IfModule mod_ctrls.c>
ControlsEngine        off
ControlsMaxClients    2
ControlsLog           /var/log/proftpd/controls.log
ControlsInterval      5
ControlsSocket        /var/run/proftpd/proftpd.sock
</IfModule>

<IfModule mod_ctrls_admin.c>
AdminControlsEngine off
</IfModule>

#
# Alternative authentication frameworks
#
#Include /etc/proftpd/ldap.conf
#Include /etc/proftpd/sql.conf

#
# This is used for FTPS connections
#
#Include /etc/proftpd/tls.conf

#
# Useful to keep VirtualHost/VirtualRoot directives separated
#
#Include /etc/proftpd/virtuals.conf

# A basic anonymous configuration, no upload directories.

# <Anonymous ~ftp>
#   User        ftp
#   Group       nogroup
#   # We want clients to be able to login with "anonymous" as well as "ftp"
#   UserAlias     anonymous ftp
#   # Cosmetic changes, all files belongs to ftp user
#   DirFakeUser on ftp
#   DirFakeGroup on ftp
# 
#   RequireValidShell   off
# 
#   # Limit the maximum number of anonymous logins
#   MaxClients      10
# 
#   # We want 'welcome.msg' displayed at login, and '.message' displayed
#   # in each newly chdired directory.
#   DisplayLogin      welcome.msg
#   DisplayChdir    .message
# 
#   # Limit WRITE everywhere in the anonymous chroot
#   <Directory *>
#     <Limit WRITE>
#       DenyAll
#     </Limit>
#   </Directory>
# 
#   # Uncomment this if you're brave.
#   # <Directory incoming>
#   #   # Umask 022 is a good standard umask to prevent new files and dirs
#   #   # (second parm) from being group and world writable.
#   #   Umask       022  022
#   #            <Limit READ WRITE>
#   #            DenyAll
#   #            </Limit>
#   #            <Limit STOR>
#   #            AllowAll
#   #            </Limit>
#   # </Directory>
# 
# </Anonymous>

# Include other custom configuration files
Include /etc/proftpd/conf.d/
">/etc/proftpd/proftpd.conf


#remise en place de la carte 1
 echo >/etc/network/interfaces
  echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address $IPServDhcp
netmask $MaskServDhcp
">/etc/network/interfaces
  service networking restart

}







#----------------------fontion instaltion Samba

function Samba(){

#test de connection avec le dns de google si ça ne marche pas passage de la carte 1 en dhcp
if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
  echo "IPv4 is up"
else
  echo >/etc/network/interfaces
  echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp">/etc/network/interfaces
    service networking restart
fi
 
echo "installation des paquets"
     apt-get update
     sudo apt-get install samba
     apt-get install sudo

#config Samba dans le smb.conf--------------
echo "
 
#-------------------------------#
#   Option general du serveur   #
#-------------------------------#

[global]

# Nom du groupe de travail ou du domaine
workgroup = ILARIA

# nom de la machine (= hostname)
netbios name = SRVL

# Nom qui apparait lors du parcours reseau (%h = hostname)
server string = %h

# Activation du cryptage des mots de passe
encrypt passwords = yes

# Mode authentification 
# - share = ok pour tous
# - user = oblige d'avoir un compte sur le serveur samba
# - domain = pour joindre un domain
security = user

# Traitement des utilisateurs anonymes
map to guest = Bad User

# Liste des utilisateurs non valides
; invalid users = root

# Pour pouvoir synchroniser l'horloge des clients sur celle du serveur
time server = Yes

 

# Configuration des logs du serveur
log file = /var/log/samba/%m.log

# Taille maximal des logs (en kb)
max log size = 1000


#------------------------------------------#
#   Option pour un controleur de domaine   #
#------------------------------------------#

# L'option ci-dessous definit Samba comme le Controleur de domane
# principal (maitre). Ceci permet a Samba de collationner les listes
# de partages entre les sous-reseaux
domain master = yes

# Le niveau d'OS indique l'importance de ce serveur en tant que
# candidat au role de controleur principal lorsqu'une election
# est provoquee
os level = 33

# L'option ci-dessous indique samba de forcer une election de controleur
# de domaine au demarrage, et lui donne ainsi une petite chance de gagner
# lors de cette éction
preferred master = yes

# Activez ce qui suit si vous voulez activer des "logon scripts"
# lorsque les utilisateurs se connectent sur des postes
# Win95, 98, Me ou NT :
domain logons = yes


# Administrateur du domaine
; admin users = root @adm

# Utilisation de WINS pour la resolution des noms NETBIOS
wins support = yes
dns proxy = no

# Ordre de resolution des noms NETBIOS
name resolve order = lmhosts wins host bcast

# Synchronisation des mots de passe samba avec les mots de passe Linux.
# Ajouter ces options si l'on veut que l'utilisateur connecte sur un domaine
# puisse changer son mdp
unix password sync = Yes
passwd program = /usr/bin/passwd %u




#-----------------------------------------#
#   Option pour les partages de dossiers  #
#-----------------------------------------#

# Le partage ci-dessous apparaitra comme repertoire personnel
# (et donc a son nom) pour l'utilisateur qui se connecte au serveur.
# Samba remplacera automatiquement homes par le nom de l'utilisateur.
[homes]
comment = Home Directories
browseable = no
writable = yes
 

[public]
# Partage du dossier public, visible et accessible par tout le monde
comment = Repertoire public sur serveur
writable = yes
path = /home/partage
guest ok = yes

[homes]

  comment = Home Directories
  browseable = no
  writeable = yes



">/etc/samba/smb.conf
service smbd restart
#recuperation des users samba et linux
echo "Renseignez l'utilisateur linux (qui servira pour entrer pour le dossier de partage)"
read UserLinux
echo "Renseignez l'utilisateur samba(identique a celui linux)"
read UserSamba
#creation
adduser $UserLinux
smbpasswd -a $UserSamba
#creation du dossier de partage et attibtion de droit, il correspont a celui parametré dans le smb.conf
mkdir /home/partage
chmod 777 /home/partage/

}











#----------------------fontion instaltion intranet



function Intranet(){
#recuperation des paquets apache=>MYSQL  et php5 indispensable pour linterface intranet en php
apt-get install apache2
apt-get install mysql-server
apt-get install php5 php-pear php5-mysql
service apache2 restart
#suppression de tout fichier par default qui s'affiche sur le serveur web
rm -R /var/www/html/*
#ecriture du script php pour affichage
echo '

<!DOCTYPE html>
<html lang="en">
<head>
  <title>acess</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="//code.jquery.com/ui/1.11.4/themes/smoothness/jquery-ui.css">
  <script src="//code.jquery.com/jquery-1.10.2.js"></script>
  <script src="//code.jquery.com/ui/1.11.4/jquery-ui.js"></script>
  <link rel="stylesheet" href="/resources/demos/style.css">
 <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css"> 
 <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">
 <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>

 
 <script src="//code.jquery.com/ui/1.11.4/jquery-ui.js"></script>
 
 

<!-- ------------------------bootstrap material---------------------------- -->
<!-- Material Design fonts -->
<link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/css?family=Roboto:300,400,500,700">
<link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/icon?family=Material+Icons">

<!-- Bootstrap -->
<link rel="stylesheet" type="text/css" href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css">

<!-- Bootstrap Material Design -->
<link rel="stylesheet" type="text/css" href="dist/css/bootstrap-material-design.css">
<link rel="stylesheet" type="text/css" href="dist/css/ripples.min.css">


<!-- ------------------------bootstrap material surcouche---------------------------- -->
    <link rel="stylesheet" href="https://storage.googleapis.com/code.getmdl.io/1.0.0/material.indigo-pink.min.css">
    <link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">

<script src="https://storage.googleapis.com/code.getmdl.io/1.0.0/material.min.js"></script>
</head>
<body>

<?php

  
// Location to file
$db = 'C:\wamp\www\parc.accdb';
if(!file_exists($db)){
 die('Error finding access database');
}
// Connection to ms access
$conn = new PDO("odbc:Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=".$db.";Uid=; Pwd=;");

$sql =  'SELECT id,ip,mac,nom,salle FROM machines ORDER BY nom';
echo "
<div class=\"table-responsive table-container\">
 <table class=\"table table-hover\">
<thead>
            <tr>
                <th>nom</th>
                <th>ip</th>
                <th>mac</th>
                <th>salle</th>
            </tr>
</thead>
<tbody>
 ";

    foreach  ($conn->query($sql) as $row) {
        echo "  <tr>";

        echo "<td>". $row['nom'] . "</td>";
        echo "<td>".  $row['ip'] . "</td>";
        echo "<td>".  $row['mac'] . "</td>";
        echo "<td>". $row['salle'] . "</td>";
        echo "</tr>";
  }

echo " </tbody>
    </table>
</div>";


?>

<form  action="#" method="post">

    <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label ">
        <label for="ip" class="mdl-textfield__label">ip</label>
        <input type="text" class="mdl-textfield__input" id="ip" name="ip" value="ip"/>
    </div>
    <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label ">
        <label for="mac" class="mdl-textfield__label">mac</label>
        <input type="text" class="mdl-textfield__input" id="mac" name="mac" value="mac"/>
    </div>
    <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label ">
        <label for="nom" class="mdl-textfield__label">nom</label>
        <input type="text" class="mdl-textfield__input" id="nom" name="nom" value="nom"/>
    </div>
    <div class="mdl-textfield mdl-js-textfield mdl-textfield--floating-label ">
        <label for="salle" class="mdl-textfield__label">salle</label>
        <input type="text" class="mdl-textfield__input" id="salle" name="salle" value="salle"/>
    </div>
 
  <input type="submit" value="submit"name="submit"/>

 

</form>




 



<script src="https://storage.googleapis.com/code.getmdl.io/1.0.0/material.min.js"></script>

</body>
</html>
<?php 

if (isset($_POST["submit"])) {
  echo "string";
$ip=$_POST["ip"];
$mac=$_POST["mac"];
$nom=$_POST["nom"];
$salle=$_POST["salle"];

//recuperer last id
 $id_sql = 'SELECT @@IDENTITY FROM machines';
$sth=$conn->query( $id_sql);
$idtemp = $sth->fetchAll(PDO::FETCH_ASSOC);
end($idtemp);         // move the internal pointer to the end of the array
$id = key($idtemp);
$id+=2;
echo "$id";
//inserer les valeur
$sql = "INSERT INTO machines (id,ip,mac,nom,salle)
VALUES ('$id','$ip', '$mac', '$nom','$salle')";
$conn->query($sql);
}

 ?>



'>/var/www/html/index.php
sudo /etc/init.d/apache2 start

}









#----------------------fontion instaltion NFS


function Nfs(){
echo "Renseignez IP du serveur NFS"
read IPServPrincipale
echo "Renseignez mask du serveur NFS"
read DNSServPrincipale
echo "Indiquez un chemin de dossier absolue a partager"
read Chemin
echo "Renseignez IP du Client NFS"
read IPClient
#test de connection avec le dns de google si ça ne marche pas passage de la carte 1 en dhcp
if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
  echo "IPv4 is up"
else
  echo >/etc/network/interfaces
  echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp">/etc/network/interfaces
    service networking restart
fi
#install du paquet nfs
aptitude install nfs-kernel-server
#creation du dossier de partage
sudo mkdir $Chemin
#ajout des autorisation pour le partage avec ladresse du serveur
echo ' /var/nfsroot  $IPClient/$DNSServPrincipale(rw,no_root_squash,subtree_check)'>>/etc/exports
#remise en place de la carte 1
echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address $IPServPrincipale
netmask $DNSServPrincipale
">/etc/network/interfaces
  service networking restart
#restart du service NFS
/etc/init.d/nfs-kernel-server reload
#activation du partage le reste se fait depuis le client linux
sudo exportfs -a

}

#----------------------fontion instaltion service sauvegarde
function Sauvegarde(){
#installation du backup-manager configuré par default pour une sauvegarde quotidienne
 sudo aptitude install backup-manager backup-manager-doc
} 




#--------------menu
echo "bonjour bienvenue 
1-Parametrer dns et hostname
2-parametrer dhcp
3-parametrer ftp
4-parametrer samba et active directori
5-parametrer interface web intranet
6-parametrer nfs
7-parametrer les sauvegarde
8-quitter
"
read choix  

 

#------------execution du menu avec un switch case
case "$choix" in

1) DNSHostname 
    ;;
2)  Dhcp 
    ;;
3) Ftp
    ;;
4) Samba
   ;;
5) Intranet
   ;;
6) Nfs
   ;;
7) Sauvegarde 
   ;;
8) echo "Merci Aurevoir" 
   ;;
*) echo "Choisissez un numero disponible dans la liste" 
   ;;
esac