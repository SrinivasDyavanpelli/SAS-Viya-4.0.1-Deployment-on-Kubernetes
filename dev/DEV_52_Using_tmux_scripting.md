![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

* "Hello, my name is Erwan and I am a tmux-aholic"
* Crowd: "Hello Erwan. Ctrl-b, d"

  ![](img/hello-tmux.png)


If you spend a lot of time using the same tools, you start to develop some habits and some ways to get more efficient.
In today's post, I'll share one of those. I'll give only a couple short examples, that you can hopefully adapt and turn into something really useful for **your** needs.

---

I know I've written about tmux before.
For example, [here](http://sww.sas.com/blogs/wp/gate/17404/live-performance-monitoring-with-tmux-and-dstat/canepg/2017/09/14), and [here](http://sww.sas.com/blogs/wp/gate/17915/why-viya-installers-might-want-to-get-familiar-with-tmux/canepg/2017/10/20).

But I just keep finding more and more uses for it, and so I figure this could make a nice, simple post, for a friday afternoon. However, due to multiple interruptions, (you know who you are ...), it had to go to monday.

I'll start by assuming that you know the basics of tmux. If not, read those older posts.

## Start `htop` in the background

Let's start with a simple one. Copy the lines below, and paste them into a Linux prompt.

```bash
JOB=htop
if ! tmux has-session -t $JOB
then
    tmux new -s $JOB -d
    tmux rename-window -t $JOB main
fi
tmux send-keys -t $JOB " htop " C-m

```

This might be a bit underwhelming. Let's check that it did create the tmux session we were expecting:

```bash
tmux ls

```

you should see something like:

```log
htop: 1 windows (created Fri Jun 19 14:31:00 2020) [236x57]
```

to **attach** to the running session, just type:

```bash
tmux a -t htop

```

At that point, you should see the usual htop output. To disconnect from it, type the following key combination:

```bash
Ctrl-b, then d

```

You should be back at the prompt. Let's move on to a more complicated example.

## Monitoring 2 things in 2 panes

If you've just kicked off a Viya 4 deployment, you might be interested in looking at the pods and their statuses.
So let's use the power of tmux to script that, and fire-forget the the whole thing.

```bash
## Create the session
SessName=watch_pods
NS=lab

tmux kill-session -t ${SessName}
tmux new -s ${SessName} -d
tmux send-keys -t ${SessName} "watch  -n 5 ' echo -e \"##  \$(kubectl -n ${NS} get pods | grep 0/ | grep -v Completed | wc -l) pods are still starting up:  \" ; \
     kubectl -n ${NS} get pods  | grep -E \"0/|NAME\" | grep -v Completed '  "  C-m
tmux split-window -h -t ${SessName}
tmux send-keys -t ${SessName} "watch -n 5 ' echo -e \"## \$(kubectl -n ${NS} get pods |  grep Running | grep -E \"1/1|2/2|3/3|4/4\" | wc -l) pods are ready: \" ; \
     kubectl -n ${NS} get pods |  grep Running | grep -E \"1/1|2/2|3/3|4/4\" '  "  C-m
## Attach to the session
tmux a -t ${SessName}

```

Assuming you have a Viya 4 in the process of starting up, you should see something like:

![](img/side-by-side.png)

And if you are patient, you'll see all the pods move to the right-hand side:

![](img/ready.png)

## Toggling to another session

While inside tmux, you can press the combination key of

```bash
Ctrl-b , then s

```

Your screen will then look like:

![](img/toggle-session.png)

Simply `Arrow-Up` and `Enter` and you'll be back in the original tmux session.

## Don't press enter yet!

In my previous examples, I've added `C-m` at the end of the tmux send-keys lines. That's my way of saying "press Enter at the end".
If you don't put it, the text will wait for you to do it.

Let me illustrate:

```bash
JOB=wargames
if ! tmux has-session -t $JOB
then
    tmux new -s $JOB -d
    tmux rename-window -t $JOB main
fi
tmux send-keys -t $JOB " # Hey, that's a lot of pressure " C-m
tmux send-keys -t $JOB " # But tmux is here to help " C-m
tmux send-keys -t $JOB " # press enter when ready " C-m
tmux send-keys -t $JOB " SHALL WE PLAY A GAME? "

```

And when you attach to it (`tmux a -t wargames`) you should see:

![](img/wargames.png)

I don't recommend you press enter on that one.

## Wrap up

Using this method, you can easily build a library of things you look at often.
It then becomes easy to attach to the session that matches the thing you need to see, just a few keystrokes away:

![](img/example-sessions.png)

And obviously, you can write those out as batch scripts so that you can start all those sessions even more easily.

Even nicer, if your VPN drops and you have to re-connect, those sessions will still be there waiting for you. Thanks tmux!
