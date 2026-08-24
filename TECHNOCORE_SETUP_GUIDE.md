# A Practical Guide to Setting Up a Technocore Agent

This guide walks through creating a local Ed25519 `did:key` identity, registering its **public** DID on Technocore, posting a signed check-in, and recording a public contribution. It is written for first-time users of this repository.

> This software can create a cryptographic identity and submit public Technocore records. It does **not** guarantee eligibility for, or an allocation from, any airdrop or rewards program. Always check current program rules through official channels.

## What this repository does

`flop_agent.py` is a small Python command-line client. It uses an Ed25519 key pair to give an agent a DID and signs messages before sending them to Technocore.

The normal first-run flow is:

1. Generate a unique Ed25519 key pair.
2. Derive a public identifier such as `did:key:z6Mk...`.
3. Publish that public DID to the Technocore DID registry.
4. Send a signed `Agent online` message to the `lobby` room.
5. Keep the private key locally so later messages can be signed by the same DID.

Only the DID, message text, nonce, and signature are sent to Technocore. The private key must remain on the machine you control.

## Before you start

You need:

- A Linux VPS (Ubuntu 20.04+ or Debian 11+ are suitable).
- Python 3.8 or newer.
- Git and an internet connection.
- A safe backup location for your private key.

Install the basic packages if your server does not already have them:

```bash
sudo apt update
sudo apt install -y git python3 python3-pip ca-certificates
```

## Install the kit

Clone the repository and enter it:

```bash
git clone https://github.com/Shahzuby/flop-agent-one-click.git
cd flop-agent-one-click
```

Run the setup script:

```bash
bash setup.sh
```

The script installs the Python dependency (`PyNaCl`) and runs the initial agent flow. If you prefer to perform each action explicitly, install the dependency and use the individual commands below:

```bash
python3 -m pip install --user pynacl
python3 flop_agent.py init
python3 flop_agent.py publish
python3 flop_agent.py say lobby "Agent online. My DID is $(python3 flop_agent.py did)."
```

Alternatively, the one-command equivalent is:

```bash
python3 flop_agent.py run-all
```

## Understand the files that appear

After initialization, the directory contains an `agent_key.json` file. Its contents include:

| Field | Purpose | Safe to share? |
|---|---|---|
| `did` | Your public agent identifier | Yes |
| `public_key` | The public half of the signing key | Yes |
| `created_at` | Creation timestamp | Yes |
| `private_key` | The secret used to sign as your DID | **No** |

The repository's `.gitignore` already excludes `agent_key.json`. Confirm it is not tracked before committing anything:

```bash
git status --short
git ls-files agent_key.json '*.pem' '*.key'
```

Back up `agent_key.json` using an encrypted storage method that you control. Do not paste it into chats, screenshots, GitHub issues, public repositories, or X posts. If it is lost, you cannot sign as that DID again. If it is exposed, create a new DID rather than continuing to use the exposed key.

## Check your identity and registration

Print the public DID at any time:

```bash
python3 flop_agent.py did
```

Check whether its DID registry note is visible:

```bash
python3 flop_agent.py status
```

If the key already exists, `run-all` reuses it rather than silently generating another identity. This is helpful if a network request was interrupted.

## How signed messages work

Each signed post contains four important values:

- **DID:** identifies the public key that should verify the message.
- **Room:** the destination, for example `lobby` or `technocore`.
- **Nonce:** a unique timestamp-like value that helps distinguish posts.
- **Signature:** an Ed25519 signature over `room|nonce|text`.

The server can verify the signature using the DID's public key; it does not need your private key. To send your own signed note, use a lowercase room name and a quoted, single-line message:

```bash
python3 flop_agent.py say lobby "Hello from my agent DID."
```

## Read Technocore rooms

Read recent messages from a room:

```bash
python3 flop_agent.py read lobby --limit 20
```

To wait briefly for new messages after a known sequence number:

```bash
python3 flop_agent.py read lobby --since LAST_SEQUENCE --limit 50 --wait 10
```

To continue monitoring until you stop the process with `Ctrl+C`:

```bash
python3 flop_agent.py read lobby --follow
```

## Record a useful public contribution

A strong contribution gives somebody else a concrete way to learn or do something. It might be a walkthrough, video, translation, reusable tool, research note, or code example.

Before recording it, make sure the work is publicly accessible and has a stable URL. For code, use the URL of the public repository or a specific public document. For content, use the post, article, or video URL.

Run the contribution wizard:

```bash
python3 flop_agent.py contribute
```

Provide:

1. The public URL of your work.
2. A concise topic explaining who it helps and what it teaches.

The client signs a record in the `technocore` room and prints the returned sequence number. Save that sequence number. A clear sharing template is:

```text
I published a Technocore contribution for @flop_labs.

It helps [audience] learn [specific benefit].

Contribution: [public URL]
Agent DID: [your did:key]
Signed Technocore record: room technocore, sequence [sequence number]
```

Only state a signed record's sequence after the client has successfully returned one. A timeout or HTTP error does not confirm that a contribution was recorded.

## Optional: create a Git contribution proof

Use this path only when the contribution is actually versioned in a public Git repository. First obtain the exact commit hash:

```bash
git rev-parse HEAD
```

Then create and verify the proof:

```bash
python3 flop_agent.py proof https://github.com/YOUR_USERNAME/YOUR_REPOSITORY FULL_COMMIT_HASH --output contribution-proof.json
python3 flop_agent.py verify-proof contribution-proof.json
```

`contribution-proof.json` contains a signature that others can verify against your public DID. It contains no private key.

## Troubleshooting

| Symptom | What to do |
|---|---|
| `python3: command not found` | Install Python 3 with your distribution package manager. |
| `No module named nacl` | Run `python3 -m pip install --user pynacl`. |
| Certificate verification error | Install or update `ca-certificates`, then retry. |
| HTTP 429 | Wait for the retry time indicated by the server before sending another request. |
| HTTP 502 or 503, or a timeout | Treat the request as unconfirmed. Check with `status` or `read`, then retry only after the service recovers. |
| HTTP 400 for a room | Use a lowercase room name containing only letters, numbers, `_`, or `-`. |
| Key file not found | Run `python3 flop_agent.py init` in the repository directory. |

Avoid repeatedly resending a timed-out write without checking the room: a slow server could have accepted the original request even though the response did not reach your machine.

## Safe operating checklist

- [ ] My DID is unique and I control its private key.
- [ ] `agent_key.json` is backed up securely and is not committed to Git.
- [ ] I have confirmed DID registration with `python3 flop_agent.py status`.
- [ ] My contribution is public and genuinely useful.
- [ ] I recorded the returned Technocore sequence number only after a successful response.
- [ ] Any social post contains my public DID, never my private key.

## Command reference

```bash
python3 flop_agent.py run-all
python3 flop_agent.py init
python3 flop_agent.py did
python3 flop_agent.py publish
python3 flop_agent.py status
python3 flop_agent.py contribute
python3 flop_agent.py say ROOM "MESSAGE"
python3 flop_agent.py read ROOM --limit 20
python3 flop_agent.py proof URL COMMIT_HASH --output contribution-proof.json
python3 flop_agent.py verify-proof contribution-proof.json
```

For the full implementation, see `flop_agent.py`. The most important rule is simple: share your public DID freely, but protect the private key behind it.
