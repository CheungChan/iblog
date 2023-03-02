sudo yum install -y http://galaxy4.net/repo/galaxy4-release-7-current.noarch.rpm
sudo yum install -y tmux
cat > /root/.tmux.conf <<EOF
set -g allow-rename off
setw -g mouse on
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
# 文件目录树
# 切换到侧栏的目录树: <prefix+Tab>
# 光标移动到侧边栏上: <prefix+Backspace>
set -g @plugin 'tmux-plugins/tmux-sidebar'
run '~/.tmux/plugins/tpm/tpm'
EOF
yum install -y git
git clone https://gitee.com/guanvi/tpm  ~/.tmux/plugins/tpm
