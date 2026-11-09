/** Les avatars illustrés proposés aux auteurs à la place d'une photo (design/site-art/manifest-avatars.json,
 *  direction affiche du site). Les fichiers vivent dans web/public/avatars/ ; au choix, le serveur copie
 *  l'avatar dans la photo du Studio (studio-photos/<uid>/avatar.webp), puis tout suit le chemin d'une
 *  photo : publique à l'approbation, affichée dans les apps. */
export const AVATARS = Array.from({ length: 20 }, (_, i) => `avatar_${String(i + 1).padStart(2, "0")}`);

export function avatarUrl(name: string): string {
  return `/avatars/${name}.webp`;
}

export function isAvatarName(name: string): boolean {
  return AVATARS.includes(name);
}
