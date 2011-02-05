
dotfiles
========

These Vim settings are largely copied from Steve Losh's
(http://stevelosh.com/blog/2010/09/coming-home-to-vim/) dotfiles repository on
bitbucket.org (http://bitbucket.org/sjl/dotfiles/src) (a Mercurial repo hub) so
I couldn't simply fork it on github. The main purpose of this repo to make my
favorite MacVim settings available to me anywhere, and anyone else is welcome
to use and extend them. There is a much bigger emphasis on Perl support than
Steve's files which are much more Ruby oriented.

Of course, it would be nicer to use Padre (http://padre.perlide.org/) but it's not quite there yet.

Installation
------------

Clone the repository into your home directory
  git clone git://github.com/garyaj/dotvim.git

and create a symbolic link to the vim subdirectory e.g.:
  ln -s dotvim/vim .vim
Then create a symbolic link to the vimrc file:
  ln -s dotvim/vim/vimrc .vimrc

Credits
-------

- Steve Losh's "Coming Home to Vim" blog posting (http://stevelosh.com/blog/2010/09/coming-home-to-vim/)
  
- Steve Losh's 'dotfiles' repository on BitBucket
  (http://bitbucket.org/sjl/dotfiles/src)
