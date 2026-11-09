import { container } from "@/components/ui";

/** Le squelette affiché pendant que la page du Studio charge : la navigation répond tout de suite. */
export default function StudioLoading() {
  return (
    <div className="flex flex-1 flex-col" aria-busy="true" aria-label="Loading">
      <div className="border-b border-line bg-white">
        <div className={`${container} flex items-center gap-6 py-4`}>
          <div className="h-7 w-20 animate-pulse rounded-lg bg-tint" />
          <div className="h-4 w-24 animate-pulse rounded bg-paper" />
          <div className="h-4 w-24 animate-pulse rounded bg-paper" />
          <div className="h-4 w-24 animate-pulse rounded bg-paper" />
          <div className="ml-auto h-10 w-36 animate-pulse rounded-xl bg-tint" />
        </div>
      </div>
      <div className={`${container} flex flex-col gap-6 pt-8`}>
        <div className="h-9 w-72 animate-pulse rounded-lg bg-tint" />
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {[0, 1, 2, 3].map((i) => (
            <div key={i} className="h-28 animate-pulse rounded-card border border-line bg-white" />
          ))}
        </div>
        <div className="h-64 animate-pulse rounded-card border border-line bg-white" />
      </div>
    </div>
  );
}
