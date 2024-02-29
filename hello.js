function main(args){
  return {
    body: `Hello, ${args.name || "World!"}`
  }
}
