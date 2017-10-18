use strict;
use warnings;

use Data::Dumper;
use Digest::SHA;
use File::Copy;
use File::Path qw( make_path rmtree );
use Module::Build;

our $VERSION = '1.0.0';

our $INSTALL_BASE = '/opt/ssh-sc';

my $class = Module::Build->subclass( code => <<'EOF');
    sub make_dir {
        my ( $dirs, $mode ) = @_;

        for my $dir ( @$dirs ) {
            if ( ! -d $dir ) {
                printf "mkdir %s\n", $dir;
                mkdir $dir;
            }
            chmod $mode, $dir;
        }
    }

    sub ACTION_install {
        my $self = shift;

        # Account for destdir
        $self->install_base($self->destdir() . $self->install_base());

        # Create the directory structure
        make_dir (
            [
                $self->install_base,
                $self->install_base . '/sbin',
                $self->install_base . '/doc',
                $self->install_base . '/etc',
                $self->install_base . '/etc/ssl',
                $self->install_base . '/man',
                $self->install_base . '/man/man1',
                $self->install_base . '/man/man5',
            ], 0750,
        );

        # Call the parent install function
        $self->SUPER::ACTION_install;
    }

    sub ACTION_uninstall {
        my $self = shift;

        # Account for destdir
        $self->install_base($self->destdir() . $self->install_base());

        if ( -d $self->install_base() ) {
            printf "Removing %s\n", $self->install_base();
            File::Path::rmtree($self->install_base(), 1, 1);
        }
    }

    sub process_sbin_files {
        my $self = shift;

        if ( $self->invoked_action() eq 'install' ) {

            my $files = $self->{'properties'}->{'sbin_files'};
            while ( my ( $src, $dst ) = each %$files ) {
                printf "Installing %s/%s\n", $self->install_base(), $dst;
                File::Copy::copy( $self->base_dir() . '/' . $src, $self->install_base() . '/' . $dst);
                chmod 0750, $self->install_base() . '/' . $dst;
            }

            # Search for POD and create man1 pages
            use Pod::Man;
            use Pod::Find qw(pod_find);
            use File::Basename;
            my $man1dir      = $self->install_base() . '/man/man1';
            my $dist_version = $self->dist_version();
            my %pods = pod_find({},( $self->base_dir() . '/sbin'));
            foreach my $pod ( keys %pods ) {
                my $pod_rel = $pod;
                my $base_dir = $self->base_dir();
                $pod_rel =~ s/${base_dir}\///mx; 
                my $man1page = $man1dir . '/' . basename($pod, '.pod') . '.1';
                printf "Manifying %s -> %s\n", $pod_rel, $man1page;
                my $parser = Pod::Man->new(
                    release => "ssh-sc v$dist_version", section => 1
                );
                $parser->parse_from_file( $pod, $man1page );
                chmod 0640, $man1page;
            }
        }

    }

    sub process_etc_files {
        my $self = shift;

        use Digest::SHA;

        if ( $self->invoked_action() eq 'install' ) {
            my $files = $self->{'properties'}->{'etc_files'};
            while ( my ( $src, $dst ) =  each %$files ) {

                if ( -f $self->install_base() . '/' . $dst ) {
                    printf "Skipping %s/%s (pre-existing)\n", $self->install_base(), $dst;
                    next;
                }

                printf "Installing %s/%s\n", $self->install_base(), $dst;
                File::Copy::copy( $self->base_dir() . '/' . $src, $self->install_base() . '/' . $dst);
                chmod 0640, $self->install_base() . '/' . $dst;
            }
        
            # Search for POD and create man5 pages
            use Pod::Man;
            use Pod::Find qw(pod_find);
            use File::Basename;
            my $man5dir      = $self->install_base() . '/man/man5';
            my $dist_version = $self->dist_version();
            my %pods = pod_find({},( $self->base_dir() . '/etc'));
            foreach my $pod ( keys %pods ) {
                my $pod_rel = $pod;
                my $base_dir = $self->base_dir();
                $pod_rel =~ s/${base_dir}\///mx; 
                my $man5page = $man5dir . '/' . basename($pod, '.pod') . '.5';
                printf "Manifying %s -> %s\n", $pod_rel, $man5page;
                my $parser = Pod::Man->new(
                    release => "ssh-sc v$dist_version", section => 5
                );
                $parser->parse_from_file( $pod, $man5page );
                chmod 0640, $man5page;
            }
        }
    }
EOF

my $build = $class->new(
    dist_name         => 'ssh-sc',
    module_name       => 'ssh-sc',
    dist_version      => $VERSION,
    dist_author       => 'Bennett Samowich <bennett@foolean.org',
    dist_abstract     => 'SSH AuthorizedKeysCommand for SmartCard Authentication',
    extra_manify_args => { release => "ssh-sc v$VERSION" },
    license           => 'perl',
    install_base      => $INSTALL_BASE,
    sbin_files         => {
        'sbin/ssh-sc-auth' => 'sbin/ssh-sc-auth',
    },
    doc_files => { 'README' => 'doc/README.dist', },
    etc_files => {
        'etc/ssh-sc-auth.conf' => 'etc/ssh-sc-auth.conf',
    },
    requires  => {
        'Config::General'       => 0,
        'Crypt::OpenSSL::RSA'   => 0,
        'Crypt::OpenSSL::X509'  => 0,
        'File::Basename'        => 0,
        'Getopt::Long'          => 0,
        'IPC::Open3'            => 0,
        'Net::LDAPS'            => 0,
        'Proc::ProcessTable'    => 0,
        'Scalar::Util'          => 0,
        'Sys::Hostname'         => 0,
        'Sys::Syslog'           => 0,
        'strict'                => 0,
        'warnings'              => 0,
    },
    build_requires => {
        'Digest::SHA'        => 0,
        'Module::Build'      => 0,
        'Pod::Find'          => 0,
        'Pod::Man'           => 0,
        'Test::More'         => 0,
        'Test::Perl::Critic' => '>= 1.01',
    },
);

my $install_base = $build->install_base();
$build->install_path( 'sbin' => $install_base . '/sbin' );
$build->install_path( 'doc'  => $install_base . '/doc' );
$build->install_path( 'etc'  => $install_base . '/etc' );

$build->add_build_element('sbin');
$build->add_build_element('doc');
$build->add_build_element('etc');
$build->create_build_script;

# Announce what the user is to do next
printf "\nTo install '%s' 'v%s' into '%s', run:\n",
  $build->dist_name(), $build->dist_version, $build->install_base();
printf "\t./Build\n\t./Build test\n\t./Build install\n";
printf "\n";
printf "Note: you should create a user who will run %s and\n",
  $build->dist_name();
printf "ensure that %s files are only owned by root,\n",
  $build->install_base();
printf "group readable by the AuthenticationKeyCommandUser.\n\n";
printf "Example:\n";
printf "      useradd -d %s -s /usr/sbin/nologin ssh-auth\n",
  $build->install_base();
printf "      chown -R root.ssh-auth %s\n", $build->install_base();
printf "      find %s -type d -exec chmod 750 {} \\;\n",
  $build->install_base();
printf "      find %s -type f -exec chmod 640 {} \\;\n",
  $build->install_base();
printf "      chmod 750 %s/sbin/*\n", $build->install_base();
