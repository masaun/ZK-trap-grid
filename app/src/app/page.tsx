import Link from 'next/link';

export default function Home() {
  return (
    <div className="min-h-screen flex items-center justify-center p-8">
      <div className="max-w-4xl w-full">
        <h1 className="text-5xl font-bold text-center mb-4">
          ZK Trap Grid Game
        </h1>
        <p className="text-center text-xl text-gray-600 dark:text-gray-400 mb-12">
          A Zero-Knowledge Proof game on Stellar blockchain
        </p>

        <div className="grid md:grid-cols-2 gap-8">
          <Link href="/defender" className="card hover:shadow-2xl transition-shadow cursor-pointer">
            <div className="text-center">
              <div className="text-6xl mb-4">🛡️</div>
              <h2 className="text-3xl font-bold mb-2">Player A</h2>
              <h3 className="text-xl text-primary font-semibold mb-3">
                Defender
              </h3>
              <p className="text-gray-600 dark:text-gray-400 mb-4">
                Set up your trap grid and commit to it using a Merkle root.
                Prove hits/misses with zero-knowledge proofs.
              </p>
              <div className="btn btn-primary w-full">
                Enter as Defender →
              </div>
            </div>
          </Link>

          <Link href="/attacker" className="card hover:shadow-2xl transition-shadow cursor-pointer">
            <div className="text-center">
              <div className="text-6xl mb-4">⚔️</div>
              <h2 className="text-3xl font-bold mb-2">Player B</h2>
              <h3 className="text-xl text-secondary font-semibold mb-3">
                Attacker
              </h3>
              <p className="text-gray-600 dark:text-gray-400 mb-4">
                Join a game and make moves to discover hidden traps.
                Trust the defender's responses through ZK proofs.
              </p>
              <div className="btn btn-secondary w-full">
                Enter as Attacker →
              </div>
            </div>
          </Link>
        </div>

        <div className="card mt-12">
          <h3 className="text-2xl font-bold mb-4">How It Works</h3>
          <div className="space-y-3 text-gray-700 dark:text-gray-300">
            <div className="flex gap-3">
              <span className="font-bold text-primary">1.</span>
              <p>
                <strong>Defender (Player A)</strong> sets up an 8x8 grid with
                hidden traps and commits the trap positions using a Merkle root.
              </p>
            </div>
            <div className="flex gap-3">
              <span className="font-bold text-primary">2.</span>
              <p>
                The game starts on-chain with the Merkle root commitment and
                both players' stakes.
              </p>
            </div>
            <div className="flex gap-3">
              <span className="font-bold text-primary">3.</span>
              <p>
                <strong>Attacker (Player B)</strong> makes moves by selecting
                grid cells to check for traps.
              </p>
            </div>
            <div className="flex gap-3">
              <span className="font-bold text-primary">4.</span>
              <p>
                Defender responds with a <strong>zero-knowledge proof</strong>
                that proves hit/miss without revealing trap locations.
              </p>
            </div>
            <div className="flex gap-3">
              <span className="font-bold text-primary">5.</span>
              <p>
                The on-chain verifier validates the proof, ensuring the defender
                cannot cheat.
              </p>
            </div>
            <div className="flex gap-3">
              <span className="font-bold text-primary">6.</span>
              <p>
                After all moves, the winner is determined based on the hit rate
                and rewards are distributed.
              </p>
            </div>
          </div>
        </div>

        <div className="card mt-8 bg-yellow-50 dark:bg-yellow-900">
          <h3 className="text-xl font-bold mb-2">⚠️ Demo Version</h3>
          <p className="text-sm">
            This is running on a local Stellar network. Make sure you have:
          </p>
          <ul className="list-disc list-inside text-sm mt-2 space-y-1">
            <li>Freighter wallet installed</li>
            <li>Local Stellar network running</li>
            <li>Contracts deployed (Game Hub, Trap Grid, Verifier)</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
